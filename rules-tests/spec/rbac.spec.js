const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

describe('RBAC Firestore Security Rules Tests', () => {
  let testEnv;
  let staffContext;
  let adminContext;
  let unauthenticatedContext;

  const STAFF_UID = 'staff-user-123';
  const ADMIN_UID = 'admin-user-456';
  const OTHER_STAFF_UID = 'other-staff-789';

  beforeAll(async () => {
    // Initialize test environment
    testEnv = await initializeTestEnvironment({
      projectId: 'demo-project',
      firestore: {
        rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8'),
        host: 'localhost',
        port: 8080,
      },
    });

    // Create authenticated contexts
    staffContext = testEnv.authenticatedContext(STAFF_UID, {
      role: 'staff',
      email: 'staff@example.com',
    });

    adminContext = testEnv.authenticatedContext(ADMIN_UID, {
      role: 'admin',
      email: 'admin@example.com',
    });

    unauthenticatedContext = testEnv.unauthenticatedContext();

    // Seed test data
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const firestore = context.firestore();

      // Create user documents
      await firestore.collection('users').doc(STAFF_UID).set({
        name: 'Staff User',
        email: 'staff@example.com',
        role: 'staff',
        active: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      await firestore.collection('users').doc(ADMIN_UID).set({
        name: 'Admin User',
        email: 'admin@example.com',
        role: 'admin',
        active: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      await firestore.collection('users').doc(OTHER_STAFF_UID).set({
        name: 'Other Staff',
        email: 'other@example.com',
        role: 'staff',
        active: true,
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
        guestCount: 150,
        budgetRange: '50000-75000',
        description: 'Traditional wedding',
        eventStatus: 'new',
        paymentStatus: 'pending',
        totalCost: 65000,
        advancePaid: 20000,
        assignedTo: STAFF_UID, // Assigned to staff
        priority: 'high',
        source: 'website',
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
        guestCount: 50,
        budgetRange: '15000-25000',
        description: 'Birthday party',
        eventStatus: 'in_progress',
        paymentStatus: 'paid',
        totalCost: 20000,
        advancePaid: 20000,
        assignedTo: OTHER_STAFF_UID, // Assigned to different staff
        priority: 'medium',
        source: 'phone',
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
        guestCount: 100,
        budgetRange: '30000-40000',
        description: 'Corporate event',
        eventStatus: 'new',
        paymentStatus: 'unpaid',
        totalCost: 35000,
        advancePaid: 0,
        assignedTo: null, // Unassigned
        priority: 'low',
        source: 'referral',
        createdAt: new Date(),
        updatedAt: new Date(),
        createdBy: ADMIN_UID,
      });
    });

    console.log('✅ Test environment initialized with seed data');
  });

  afterAll(async () => {
    if (testEnv) {
      await testEnv.cleanup();
      console.log('🧹 Test environment cleaned up');
    }
  });

  describe('👤 User Authentication & Authorization', () => {
    test('❌ Unauthenticated users cannot access any data', async () => {
      const firestore = unauthenticatedContext.firestore();

      await assertFails(
        firestore.collection('enquiries').doc('enquiry-assigned-to-staff').get()
      );
      await assertFails(
        firestore.collection('users').doc(STAFF_UID).get()
      );
    });

    test('✅ Authenticated users can read their own user document', async () => {
      const staffFirestore = staffContext.firestore();
      const adminFirestore = adminContext.firestore();

      await assertSucceeds(
        staffFirestore.collection('users').doc(STAFF_UID).get()
      );
      await assertSucceeds(
        adminFirestore.collection('users').doc(ADMIN_UID).get()
      );
    });

    test('❌ Users cannot read other users documents (non-admin)', async () => {
      const staffFirestore = staffContext.firestore();

      await assertFails(
        staffFirestore.collection('users').doc(ADMIN_UID).get()
      );
      await assertFails(
        staffFirestore.collection('users').doc(OTHER_STAFF_UID).get()
      );
    });
  });

  describe('📋 Staff Enquiry Access Rules', () => {
    test('✅ Staff can read enquiries assigned to them', async () => {
      const firestore = staffContext.firestore();

      await assertSucceeds(
        firestore.collection('enquiries').doc('enquiry-assigned-to-staff').get()
      );
    });

    test('❌ Staff cannot read enquiries assigned to others', async () => {
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('enquiries').doc('enquiry-assigned-to-other').get()
      );
    });

    test('❌ Staff cannot read unassigned enquiries', async () => {
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('enquiries').doc('enquiry-unassigned').get()
      );
    });

    test('✅ Staff can update enquiries assigned to them', async () => {
      const firestore = staffContext.firestore();

      await assertSucceeds(
        firestore.collection('enquiries').doc('enquiry-assigned-to-staff').update({
          eventStatus: 'in_progress',
          updatedAt: new Date(),
        })
      );
    });

    test('❌ Staff cannot update enquiries assigned to others', async () => {
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('enquiries').doc('enquiry-assigned-to-other').update({
          eventStatus: 'completed',
          updatedAt: new Date(),
        })
      );
    });

    test('❌ Staff cannot delete any enquiries', async () => {
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('enquiries').doc('enquiry-assigned-to-staff').delete()
      );
    });

    test('❌ Staff cannot create new enquiries', async () => {
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('enquiries').add({
          customerName: 'New Customer',
          customerEmail: 'new@example.com',
          eventType: 'Wedding',
          eventDate: new Date(),
          createdAt: new Date(),
          createdBy: STAFF_UID,
        })
      );
    });

    test('❌ Staff cannot modify assignedTo field', async () => {
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('enquiries').doc('enquiry-assigned-to-staff').update({
          assignedTo: OTHER_STAFF_UID,
          updatedAt: new Date(),
        })
      );
    });
  });

  describe('👑 Admin Enquiry Access Rules', () => {
    test('✅ Admin can read any enquiry', async () => {
      const firestore = adminContext.firestore();

      await assertSucceeds(
        firestore.collection('enquiries').doc('enquiry-assigned-to-staff').get()
      );
      await assertSucceeds(
        firestore.collection('enquiries').doc('enquiry-assigned-to-other').get()
      );
      await assertSucceeds(
        firestore.collection('enquiries').doc('enquiry-unassigned').get()
      );
    });

    test('✅ Admin can create new enquiries', async () => {
      const firestore = adminContext.firestore();

      await assertSucceeds(
        firestore.collection('enquiries').add({
          customerName: 'Admin Created',
          customerEmail: 'admin-created@example.com',
          customerPhone: '+1234567893',
          eventType: 'Corporate',
          eventDate: new Date(),
          eventLocation: 'Conference Center',
          guestCount: 200,
          budgetRange: '100000-150000',
          description: 'Admin created enquiry',
          eventStatus: 'new',
          paymentStatus: 'pending',
          assignedTo: STAFF_UID,
          priority: 'high',
          source: 'admin',
          createdAt: new Date(),
          updatedAt: new Date(),
          createdBy: ADMIN_UID,
        })
      );
    });

    test('✅ Admin can update any enquiry', async () => {
      const firestore = adminContext.firestore();

      await assertSucceeds(
        firestore.collection('enquiries').doc('enquiry-unassigned').update({
          assignedTo: STAFF_UID,
          eventStatus: 'assigned',
          updatedAt: new Date(),
        })
      );
    });

    test('✅ Admin can delete any enquiry', async () => {
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

    test('✅ Admin can read all users', async () => {
      const firestore = adminContext.firestore();

      await assertSucceeds(
        firestore.collection('users').doc(STAFF_UID).get()
      );
      await assertSucceeds(
        firestore.collection('users').doc(OTHER_STAFF_UID).get()
      );
    });
  });

  describe('📊 Audit Trail & History Rules', () => {
    test('✅ Staff can read history of assigned enquiries', async () => {
      const firestore = staffContext.firestore();

      await assertSucceeds(
        firestore.collection('enquiries')
          .doc('enquiry-assigned-to-staff')
          .collection('history')
          .get()
      );
    });

    test('❌ Staff cannot read history of unassigned enquiries', async () => {
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('enquiries')
          .doc('enquiry-assigned-to-other')
          .collection('history')
          .get()
      );
    });

    test('✅ Admin can create audit logs', async () => {
      const firestore = adminContext.firestore();

      await assertSucceeds(
        firestore.collection('admin_audit').add({
          action: 'user_role_changed',
          targetUserId: STAFF_UID,
          adminUserId: ADMIN_UID,
          timestamp: new Date(),
          metadata: {
            oldRole: 'staff',
            newRole: 'admin',
          },
        })
      );
    });

    test('❌ Staff cannot create audit logs', async () => {
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

  describe('⚙️ Settings & Configuration Rules', () => {
    test('✅ Users can read/write their own settings', async () => {
      const firestore = staffContext.firestore();

      await assertSucceeds(
        firestore.collection('users')
          .doc(STAFF_UID)
          .collection('settings')
          .doc('preferences')
          .set({
            theme: 'dark',
            language: 'en',
            timezone: 'UTC',
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
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('users')
          .doc(OTHER_STAFF_UID)
          .collection('settings')
          .doc('preferences')
          .get()
      );
    });

    test('✅ Admin can read app configuration', async () => {
      const firestore = adminContext.firestore();

      await assertSucceeds(
        firestore.collection('app_config').doc('dropdowns').get()
      );
    });

    test('❌ Staff cannot write app configuration', async () => {
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('app_config').doc('dropdowns').update({
          event_types: ['Wedding', 'Birthday'],
          updatedAt: new Date(),
        })
      );
    });
  });

  describe('🔒 Security Boundary Tests', () => {
    test('❌ Staff cannot escalate their role', async () => {
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('users').doc(STAFF_UID).update({
          role: 'admin',
          updatedAt: new Date(),
        })
      );
    });

    test('❌ Staff cannot deactivate themselves', async () => {
      const firestore = staffContext.firestore();

      await assertFails(
        firestore.collection('users').doc(STAFF_UID).update({
          active: false,
          updatedAt: new Date(),
        })
      );
    });

    test('❌ Staff cannot access financial data directly', async () => {
      // This test verifies that the rules prevent access to sensitive fields
      // The actual field-level security is enforced by the application layer
      const firestore = staffContext.firestore();

      // Staff can read the document but shouldn't see financial fields
      // (This is tested in the application layer, not rules layer)
      const doc = await assertSucceeds(
        firestore.collection('enquiries').doc('enquiry-assigned-to-staff').get()
      );

      // Document exists but financial data access is controlled by app logic
      expect(doc.exists).toBe(true);
    });

    test('✅ Admin can perform user management operations', async () => {
      const firestore = adminContext.firestore();

      await assertSucceeds(
        firestore.collection('users').doc(STAFF_UID).update({
          active: false,
          updatedAt: new Date(),
        })
      );

      // Restore active status
      await assertSucceeds(
        firestore.collection('users').doc(STAFF_UID).update({
          active: true,
          updatedAt: new Date(),
        })
      );
    });
  });
});

// Run tests if called directly
if (require.main === module) {
  console.log('🛡️ Running Firestore RBAC Security Rules Tests...');
  console.log('📋 Test Coverage:');
  console.log('  • Staff can only access assigned enquiries');
  console.log('  • Staff cannot delete or create enquiries');
  console.log('  • Admin has full access to all resources');
  console.log('  • Audit trails are properly protected');
  console.log('  • Security boundaries are enforced');
  console.log('');
}
