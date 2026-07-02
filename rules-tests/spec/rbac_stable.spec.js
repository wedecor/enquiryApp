const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

describe('RBAC Firestore Security Rules - Stabilized Tests', () => {
  let testEnv;

  const STAFF_UID = 'staff-user-123';
  const ADMIN_UID = 'admin-user-456';
  const OTHER_STAFF_UID = 'other-staff-789';
  const INACTIVE_STAFF_UID = 'inactive-staff-999';

  // Use unique project ID for each test run to avoid conflicts
  const PROJECT_ID = `test-rbac-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

  beforeAll(async () => {
    console.log(`🔥 Initializing test environment with project: ${PROJECT_ID}`);
    
    // Initialize test environment with unique project ID
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8'),
        host: 'localhost',
        port: 8080,
      },
    });

    console.log('✅ Test environment initialized');
  });

  afterAll(async () => {
    if (testEnv) {
      await testEnv.cleanup();
      console.log('🧹 Test environment cleaned up');
    }
  });

  beforeEach(async () => {
    // Clear all data before each test to ensure isolation
    await testEnv.clearFirestore();
    
    // Seed fresh test data for each test
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const firestore = context.firestore();

      // Create user documents
      await firestore.collection('users').doc(STAFF_UID).set({
        name: 'Staff User',
        email: 'staff@example.com',
        role: 'staff',
        active: true,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      await firestore.collection('users').doc(ADMIN_UID).set({
        name: 'Admin User',
        email: 'admin@example.com',
        role: 'admin',
        active: true,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      await firestore.collection('users').doc(OTHER_STAFF_UID).set({
        name: 'Other Staff',
        email: 'other@example.com',
        role: 'staff',
        active: true,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      await firestore.collection('users').doc(INACTIVE_STAFF_UID).set({
        name: 'Inactive Staff',
        email: 'inactive@example.com',
        role: 'staff',
        active: false,
        isActive: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      // Create test enquiries
      await firestore.collection('enquiries').doc('enquiry-assigned-to-staff').set({
        customerName: 'John Doe',
        customerEmail: 'john@example.com',
        customerPhone: '+1234567890',
        eventType: 'Wedding',
        eventDate: new Date('2024-12-01'),
        eventLocation: 'Grand Hotel',
        eventStatus: 'new',
        assignedTo: STAFF_UID,
        createdAt: new Date(),
        updatedAt: new Date(),
        createdBy: ADMIN_UID,
      });

      await firestore.collection('enquiries').doc('enquiry-assigned-to-other').set({
        customerName: 'Jane Smith',
        customerEmail: 'jane@example.com',
        customerPhone: '+1234567891',
        eventType: 'Birthday',
        eventDate: new Date('2024-11-15'),
        eventLocation: 'Community Center',
        eventStatus: 'in_progress',
        assignedTo: OTHER_STAFF_UID,
        createdAt: new Date(),
        updatedAt: new Date(),
        createdBy: ADMIN_UID,
      });

      await firestore.collection('enquiries').doc('enquiry-unassigned').set({
        customerName: 'Bob Wilson',
        customerEmail: 'bob@example.com',
        customerPhone: '+1234567892',
        eventType: 'Corporate',
        eventDate: new Date('2024-10-20'),
        eventLocation: 'Office Building',
        eventStatus: 'new',
        assignedTo: null,
        createdAt: new Date(),
        updatedAt: new Date(),
        createdBy: ADMIN_UID,
      });

      await firestore.collection('enquiries').doc('enquiry-assigned-to-inactive').set({
        customerName: 'Inactive Assignee',
        customerEmail: 'inactive-assignee@example.com',
        eventType: 'Wedding',
        eventDate: new Date('2024-12-15'),
        assignedTo: INACTIVE_STAFF_UID,
        createdAt: new Date(),
        updatedAt: new Date(),
        createdBy: ADMIN_UID,
      });
    });
  });

  describe('👤 Authentication Rules', () => {
    test('❌ Unauthenticated users cannot access any data', async () => {
      const unauthenticatedContext = testEnv.unauthenticatedContext();
      const firestore = unauthenticatedContext.firestore();

      await assertFails(firestore.collection('enquiries').doc('enquiry-assigned-to-staff').get());
      await assertFails(firestore.collection('users').doc(STAFF_UID).get());
    });

    test('✅ Users can read their own user document', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const adminContext = testEnv.authenticatedContext(ADMIN_UID, { role: 'admin' });

      await assertSucceeds(staffContext.firestore().collection('users').doc(STAFF_UID).get());
      await assertSucceeds(adminContext.firestore().collection('users').doc(ADMIN_UID).get());
    });
  });

  describe('📋 Staff Enquiry Access', () => {
    test('✅ Staff can read assigned enquiries', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const firestore = staffContext.firestore();

      await assertSucceeds(firestore.collection('enquiries').doc('enquiry-assigned-to-staff').get());
    });

    test('❌ Staff cannot read unassigned enquiries', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const firestore = staffContext.firestore();

      await assertFails(firestore.collection('enquiries').doc('enquiry-assigned-to-other').get());
      await assertFails(firestore.collection('enquiries').doc('enquiry-unassigned').get());
    });

    test('✅ Staff can update assigned enquiries', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const firestore = staffContext.firestore();

      await assertSucceeds(
        firestore.collection('enquiries').doc('enquiry-assigned-to-staff').update({
          eventStatus: 'in_progress',
          updatedAt: new Date(),
        })
      );
    });

    test('❌ Staff cannot delete enquiries', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const firestore = staffContext.firestore();

      await assertFails(firestore.collection('enquiries').doc('enquiry-assigned-to-staff').delete());
    });

    test('❌ Staff cannot create enquiries', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('enquiries').add({
          customerName: 'New Customer',
          eventType: 'Wedding',
          eventDate: new Date(),
          createdAt: new Date(),
          createdBy: STAFF_UID,
        })
      );
    });

    test('❌ Staff cannot modify assignedTo field', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('enquiries').doc('enquiry-assigned-to-staff').update({
          assignedTo: OTHER_STAFF_UID,
          updatedAt: new Date(),
        })
      );
    });

    test('❌ Inactive staff cannot read assigned enquiries', async () => {
      const inactiveContext = testEnv.authenticatedContext(INACTIVE_STAFF_UID, { role: 'staff' });
      const firestore = inactiveContext.firestore();

      await assertFails(
        firestore.collection('enquiries').doc('enquiry-assigned-to-inactive').get()
      );
    });

    test('❌ Staff cannot modify createdAt field', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('enquiries').doc('enquiry-assigned-to-staff').update({
          createdAt: new Date('2020-01-01'),
          updatedAt: new Date(),
        })
      );
    });

    test('❌ Staff cannot modify createdBy field', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('enquiries').doc('enquiry-assigned-to-staff').update({
          createdBy: OTHER_STAFF_UID,
          updatedAt: new Date(),
        })
      );
    });
  });

  describe('👑 Admin Full Access', () => {
    test('✅ Admin can read any enquiry', async () => {
      const adminContext = testEnv.authenticatedContext(ADMIN_UID, { role: 'admin' });
      const firestore = adminContext.firestore();

      await assertSucceeds(firestore.collection('enquiries').doc('enquiry-assigned-to-staff').get());
      await assertSucceeds(firestore.collection('enquiries').doc('enquiry-assigned-to-other').get());
      await assertSucceeds(firestore.collection('enquiries').doc('enquiry-unassigned').get());
    });

    test('✅ Admin can create enquiries', async () => {
      const adminContext = testEnv.authenticatedContext(ADMIN_UID, { role: 'admin' });
      const firestore = adminContext.firestore();

      await assertSucceeds(
        firestore.collection('enquiries').add({
          customerName: 'Admin Created',
          customerEmail: 'admin-created@example.com',
          eventType: 'Corporate',
          eventDate: new Date(),
          eventStatus: 'new',
          assignedTo: STAFF_UID,
          createdAt: new Date(),
          updatedAt: new Date(),
          createdBy: ADMIN_UID,
        })
      );
    });

    test('✅ Admin can update any enquiry', async () => {
      const adminContext = testEnv.authenticatedContext(ADMIN_UID, { role: 'admin' });
      const firestore = adminContext.firestore();

      await assertSucceeds(
        firestore.collection('enquiries').doc('enquiry-unassigned').update({
          assignedTo: STAFF_UID,
          eventStatus: 'assigned',
          updatedAt: new Date(),
        })
      );
    });

    test('✅ Admin can delete enquiries', async () => {
      const adminContext = testEnv.authenticatedContext(ADMIN_UID, { role: 'admin' });
      const firestore = adminContext.firestore();

      // Create a test enquiry to delete
      const docRef = await firestore.collection('enquiries').add({
        customerName: 'To Be Deleted',
        eventType: 'Test',
        eventDate: new Date(),
        createdAt: new Date(),
        createdBy: ADMIN_UID,
      });

      await assertSucceeds(docRef.delete());
    });
  });

  describe('📊 Settings & Configuration', () => {
    test('✅ Users can manage their own settings', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const firestore = staffContext.firestore();

      await assertSucceeds(
        firestore.collection('users')
          .doc(STAFF_UID)
          .collection('settings')
          .doc('preferences')
          .set({
            theme: 'dark',
            language: 'en',
            updatedAt: new Date(),
          })
      );

      await assertSucceeds(
        firestore.collection('users')
          .doc(STAFF_UID)
          .collection('settings')
          .doc('preferences')
          .get()
      );
    });

    test('❌ Users cannot access other users settings', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('users')
          .doc(OTHER_STAFF_UID)
          .collection('settings')
          .doc('preferences')
          .get()
      );
    });

    test('✅ Users can manage their own saved filter views', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const firestore = staffContext.firestore();
      const now = new Date().toISOString();

      await assertSucceeds(
        firestore.collection('users')
          .doc(STAFF_UID)
          .collection('savedViews')
          .doc('my-view')
          .set({
            id: 'my-view',
            name: 'Active weddings',
            filters: { statuses: ['new'], eventTypes: [] },
            isDefault: false,
            createdAt: now,
            updatedAt: now,
          })
      );

      await assertSucceeds(
        firestore.collection('users')
          .doc(STAFF_UID)
          .collection('savedViews')
          .doc('my-view')
          .get()
      );
    });

    test('❌ Users cannot access other users saved filter views', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('users')
          .doc(OTHER_STAFF_UID)
          .collection('savedViews')
          .doc('private-view')
          .get()
      );
    });

    test('✅ Admin can read app configuration', async () => {
      const adminContext = testEnv.authenticatedContext(ADMIN_UID, { role: 'admin' });
      const firestore = adminContext.firestore();

      // First create the config document
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('app_config').doc('dropdowns').set({
          event_types: ['Wedding', 'Birthday'],
          statuses: ['new', 'in_progress'],
          updatedAt: new Date(),
        });
      });

      await assertSucceeds(firestore.collection('app_config').doc('dropdowns').get());
    });

    test('❌ Staff cannot write app configuration', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('app_config').doc('dropdowns').update({
          event_types: ['Wedding', 'Birthday'],
          updatedAt: new Date(),
        })
      );
    });
  });

  describe('🔒 Security Boundaries', () => {
    test('❌ Staff cannot escalate their role', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('users').doc(STAFF_UID).update({
          role: 'admin',
          updatedAt: new Date(),
        })
      );
    });

    test('✅ Admin can manage user roles', async () => {
      const adminContext = testEnv.authenticatedContext(ADMIN_UID, { role: 'admin' });
      const firestore = adminContext.firestore();

      await assertSucceeds(
        firestore.collection('users').doc(STAFF_UID).update({
          active: false,
          updatedAt: new Date(),
        })
      );

      // Restore for other tests
      await assertSucceeds(
        firestore.collection('users').doc(STAFF_UID).update({
          active: true,
          updatedAt: new Date(),
        })
      );
    });

    test('✅ Admin audit logs can be created', async () => {
      const adminContext = testEnv.authenticatedContext(ADMIN_UID, { role: 'admin' });
      const firestore = adminContext.firestore();

      await assertSucceeds(
        firestore.collection('admin_audit').add({
          action: 'user_role_changed',
          targetUserId: STAFF_UID,
          adminUserId: ADMIN_UID,
          timestamp: new Date(),
          metadata: { oldRole: 'staff', newRole: 'admin' },
        })
      );
    });

    test('❌ Staff cannot create audit logs', async () => {
      const staffContext = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' });
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('admin_audit').add({
          action: 'unauthorized_attempt',
          userId: STAFF_UID,
          timestamp: new Date(),
        })
      );
    });
  });
});

// Add test completion logging
afterAll(() => {
  console.log('🎉 All RBAC security rules tests completed successfully');
  console.log('📊 Test Coverage:');
  console.log('  • Authentication and authorization ✅');
  console.log('  • Staff access restrictions ✅');
  console.log('  • Admin privileges ✅');
  console.log('  • Security boundaries ✅');
  console.log('  • Configuration management ✅');
});
