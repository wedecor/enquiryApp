self.addEventListener('push', (event) => {
  try {
    const payload = event.data?.json() || {};
    const notif = payload.notification || {};
    const title = notif.title || 'WeDecor';
    const options = {
      body: notif.body || '',
      data: payload.data || {},
      // icon: '/icons/Icon-192.png', // optionally set your app icon
      // badge: '/icons/badge.png'
    };
    event.waitUntil(self.registration.showNotification(title, options));
  } catch (_) {
    event.waitUntil(self.registration.showNotification('WeDecor', {
      body: 'You have a new update.'
    }));
  }
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const target = '/'; // Optionally deep-link using event.notification.data.enquiryId
  event.waitUntil(clients.openWindow(target));
});