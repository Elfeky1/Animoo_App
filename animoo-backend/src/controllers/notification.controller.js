const Notification = require('../models/Notification');
const Pet = require('../models/Pet');

function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function endOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59, 999);
}

function parseTimeToDate(timeText) {
  if (!timeText) return null;

  const match = timeText.trim().match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
  if (!match) return null;

  let hour = Number(match[1]);
  const minute = Number(match[2]);
  const period = match[3].toUpperCase();

  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;

  const now = new Date();
  return new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate(),
    hour,
    minute,
    0,
    0
  );
}

async function ensurePetReminderNotifications(userId) {
  const pets = await Pet.find({ user: userId });
  const now = new Date();
  const todayStart = startOfDay(now);
  const todayEnd = endOfDay(now);

  for (const pet of pets) {
    const foodTimes = Array.isArray(pet.foodReminderTimes)
      ? pet.foodReminderTimes
      : [];

    for (let i = 0; i < foodTimes.length; i += 1) {
      const foodTimeText = foodTimes[i];
      const foodTime = parseTimeToDate(foodTimeText);
      if (!foodTime || now < foodTime) continue;

      const existingFoodReminder = await Notification.findOne({
        user: userId,
        type: 'reminder',
        'meta.petId': pet._id.toString(),
        'meta.reminderKind': 'food',
        'meta.reminderIndex': i,
        createdAt: { $gte: todayStart, $lte: todayEnd },
      });

      if (!existingFoodReminder) {
        await Notification.create({
          user: userId,
          type: 'reminder',
          title: `${pet.name}'s meal time`,
          body: `It's time to feed ${pet.name} (${foodTimeText}).`,
          meta: {
            petId: pet._id.toString(),
            reminderKind: 'food',
            reminderIndex: i,
            reminderTime: foodTimeText,
          },
        });
      }
    }

    if (pet.vaccineReminderDate) {
      const vaccineDate = new Date(pet.vaccineReminderDate);
      if (!Number.isNaN(vaccineDate.getTime())) {
        const daysUntilVaccine = Math.ceil(
          (startOfDay(vaccineDate) - todayStart) / (1000 * 60 * 60 * 24)
        );

        if (daysUntilVaccine >= 0 && daysUntilVaccine <= 3) {
          const existingVaccineReminder = await Notification.findOne({
            user: userId,
            type: 'reminder',
            'meta.petId': pet._id.toString(),
            'meta.reminderKind': 'vaccine',
            'meta.vaccineReminderDate': pet.vaccineReminderDate,
          });

          if (!existingVaccineReminder) {
            const body =
                daysUntilVaccine == 0
                  ? `${pet.name}'s vaccination is due today.`
                  : `${pet.name}'s vaccination is due in ${daysUntilVaccine} day${daysUntilVaccine == 1 ? '' : 's'}.`;

            await Notification.create({
              user: userId,
              type: 'reminder',
              title: `${pet.name}'s vaccine reminder`,
              body,
              meta: {
                petId: pet._id.toString(),
                reminderKind: 'vaccine',
                vaccineReminderDate: pet.vaccineReminderDate,
              },
            });
          }
        }
      }
    }
  }
}

exports.getNotifications = async (req, res) => {
  try {
    await ensurePetReminderNotifications(req.user._id);

    const notifications = await Notification.find({ user: req.user._id }).sort({
      createdAt: -1,
    });

    res.json(notifications);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.markAllRead = async (req, res) => {
  try {
    await Notification.updateMany(
      { user: req.user._id, isRead: false },
      { isRead: true }
    );

    res.json({ message: 'Notifications marked as read' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.clearNotifications = async (req, res) => {
  try {
    await Notification.deleteMany({ user: req.user._id });
    res.json({ message: 'Notifications cleared' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
