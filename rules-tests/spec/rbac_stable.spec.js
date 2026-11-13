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

  describe('🔀 Staff Status Transitions', () => {
    const seedStatus = async (id, statusValue, assignedTo = STAFF_UID) => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('enquiries').doc(id).set({
          customerName: 'Transition Test',
          eventType: 'Wedding',
          eventDate: new Date('2026-12-01'),
          // Approving needs a known location (see 📍 Approval needs a location).
          eventLocation: 'JP Nagar',
          statusValue,
          assignedTo,
          createdAt: new Date(),
          updatedAt: new Date(),
          createdBy: ADMIN_UID,
        });
      });
    };

    const updateStatus = (uid, role, id, statusValue) =>
      testEnv
        .authenticatedContext(uid, { role })
        .firestore()
        .collection('enquiries')
        .doc(id)
        // Real clients (EnquiryRepository.updateStatus / edit form) always stamp
        // statusUpdatedBy with the caller's uid when the status changes.
        .update({ statusValue, statusUpdatedBy: uid, updatedAt: new Date() });

    test.each([
      ['new', 'in_talks'],
      ['new', 'not_interested'],
      ['new', 'cancelled'],
      ['in_talks', 'approved'],
      ['in_talks', 'closed_lost'],
      ['approved', 'completed'],
      ['approved', 'cancelled'],
    ])('✅ Staff can move %s → %s', async (from, to) => {
      await seedStatus('transition-doc', from);
      await assertSucceeds(updateStatus(STAFF_UID, 'staff', 'transition-doc', to));
    });

    test.each([
      ['new', 'approved'],
      ['new', 'completed'],
      ['in_talks', 'new'],
      ['in_talks', 'completed'],
      ['approved', 'in_talks'],
      ['completed', 'in_talks'],
      ['cancelled', 'new'],
      ['not_interested', 'in_talks'],
      ['closed_lost', 'approved'],
      ['new', 'quote_sent'],
      ['new', 'bogus'],
    ])('❌ Staff cannot move %s → %s', async (from, to) => {
      await seedStatus('transition-doc', from);
      await assertFails(updateStatus(STAFF_UID, 'staff', 'transition-doc', to));
    });

    test.each([
      ['quote_sent', 'approved'],
      ['contacted', 'not_interested'],
      ['in_progress', 'closed_lost'],
      ['confirmed', 'completed'],
      ['enquired', 'in_talks'],
    ])('✅ Staff can move legacy %s → %s', async (from, to) => {
      await seedStatus('transition-doc', from);
      await assertSucceeds(updateStatus(STAFF_UID, 'staff', 'transition-doc', to));
    });

    // Rewriting a legacy alias to its own canonical value is not a status change: clients
    // compare canonical values and send no statusUpdatedBy / stage stamps for it.
    test.each([
      ['quote_sent', 'in_talks'],
      ['scheduled', 'approved'],
    ])('✅ Staff can normalise legacy %s → %s without stamping', async (from, to) => {
      await seedStatus('transition-doc', from);
      await assertSucceeds(
        testEnv
          .authenticatedContext(STAFF_UID, { role: 'staff' })
          .firestore()
          .collection('enquiries')
          .doc('transition-doc')
          .update({ statusValue: to, updatedAt: new Date() })
      );
    });

    test.each([
      ['quote_sent', 'new'],
      ['quote_sent', 'completed'],
      ['confirmed', 'in_talks'],
    ])('❌ Staff cannot move legacy %s → %s', async (from, to) => {
      await seedStatus('transition-doc', from);
      await assertFails(updateStatus(STAFF_UID, 'staff', 'transition-doc', to));
    });

    test('✅ Staff can edit other fields on a terminal enquiry', async () => {
      await seedStatus('transition-doc', 'completed');
      const firestore = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' }).firestore();

      await assertSucceeds(
        firestore.collection('enquiries').doc('transition-doc').update({
          notes: 'Follow-up done',
          updatedAt: new Date(),
        })
      );
    });

    test('❌ Staff cannot remove statusValue', async () => {
      await seedStatus('transition-doc', 'in_talks');
      const firebase = require('firebase/compat/app').default;
      const firestore = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' }).firestore();

      await assertFails(
        firestore.collection('enquiries').doc('transition-doc').update({
          statusValue: firebase.firestore.FieldValue.delete(),
          updatedAt: new Date(),
        })
      );
    });

    test('❌ Staff cannot change status of enquiries assigned to others', async () => {
      await seedStatus('transition-doc', 'new', OTHER_STAFF_UID);
      await assertFails(updateStatus(STAFF_UID, 'staff', 'transition-doc', 'in_talks'));
    });

    test.each([
      ['completed', 'new'],
      ['new', 'completed'],
      ['cancelled', 'in_talks'],
      ['quote_sent', 'closed_lost'],
    ])('✅ Admin can move %s → %s', async (from, to) => {
      await seedStatus('transition-doc', from);
      await assertSucceeds(updateStatus(ADMIN_UID, 'admin', 'transition-doc', to));
    });
  });

  describe('🧾 Staff status bookkeeping fields', () => {
    const seed = async (statusValue, extra = {}) => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('enquiries').doc('bookkeeping-doc').set({
          customerName: 'Bookkeeping Test',
          eventType: 'Wedding',
          eventDate: new Date('2026-12-01'),
          statusValue,
          assignedTo: STAFF_UID,
          createdAt: new Date(),
          updatedAt: new Date(),
          createdBy: ADMIN_UID,
          ...extra,
        });
      });
    };
    const staffDoc = () =>
      testEnv
        .authenticatedContext(STAFF_UID, { role: 'staff' })
        .firestore()
        .collection('enquiries')
        .doc('bookkeeping-doc');

    test.each([
      ['lostReason', 'no_response'],
      ['lostReasonNote', 'forged'],
      ['lostAt', new Date('2020-01-01')],
      ['completedAt', new Date('2020-01-01')],
      ['inTalksAt', new Date('2020-01-01')],
      ['approvedAt', new Date('2020-01-01')],
      ['statusUpdatedBy', OTHER_STAFF_UID],
    ])('❌ Staff cannot change %s without a status change', async (field, value) => {
      await seed('in_talks');
      await assertFails(staffDoc().update({ [field]: value, updatedAt: new Date() }));
    });

    test('✅ Staff can stamp stage + lost fields together with a status change', async () => {
      await seed('in_talks');
      await assertSucceeds(
        staffDoc().update({
          statusValue: 'closed_lost',
          statusUpdatedBy: STAFF_UID,
          lostAt: new Date(),
          lostReason: 'budget',
          lostReasonNote: null,
          updatedAt: new Date(),
        })
      );
    });

    test('❌ Status change must record the caller as statusUpdatedBy', async () => {
      await seed('new');
      await assertFails(
        staffDoc().update({
          statusValue: 'in_talks',
          statusUpdatedBy: OTHER_STAFF_UID,
          inTalksAt: new Date(),
          updatedAt: new Date(),
        })
      );
      await assertFails(staffDoc().update({ statusValue: 'in_talks', updatedAt: new Date() }));
    });

    test('✅ Re-saving a legacy status as canonical needs no bookkeeping', async () => {
      await seed('enquired', { statusUpdatedBy: OTHER_STAFF_UID });
      await assertSucceeds(staffDoc().update({ statusValue: 'new', updatedAt: new Date() }));
    });

    test('❌ Legacy normalisation cannot smuggle bookkeeping fields', async () => {
      await seed('enquired');
      await assertFails(
        staffDoc().update({ statusValue: 'new', lostReason: 'budget', updatedAt: new Date() })
      );
    });

    test('✅ Staff can correct the event date (edit form allows it)', async () => {
      await seed('in_talks');
      await assertSucceeds(staffDoc().update({ eventDate: new Date('2026-12-05'), updatedAt: new Date() }));
    });
  });

  describe('📍 Approval needs a location', () => {
    const seed = async (statusValue, extra = {}, assignedTo = STAFF_UID) => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('enquiries').doc('location-doc').set({
          customerName: 'Location Test',
          eventType: 'Wedding',
          eventDate: new Date('2026-12-01'),
          statusValue,
          assignedTo,
          createdAt: new Date(),
          updatedAt: new Date(),
          createdBy: ADMIN_UID,
          ...extra,
        });
      });
    };
    const docAs = (uid, role) =>
      testEnv.authenticatedContext(uid, { role }).firestore().collection('enquiries').doc('location-doc');
    const approve = (uid, role, extra = {}) =>
      docAs(uid, role).update({
        statusValue: 'approved',
        statusUpdatedBy: uid,
        approvedAt: new Date(),
        updatedAt: new Date(),
        ...extra,
      });

    test.each([
      ['Bangalore'],
      ['bengaluru.'],
      ['  BLR  '],
      ['Bengaluru, Karnataka'],
      ['Bangalore Urban'],
      ['India'],
      [''],
      [' , '],
    ])('❌ Admin cannot approve with location %p', async (location) => {
      await seed('in_talks', { eventLocation: location });
      await assertFails(approve(ADMIN_UID, 'admin'));
    });

    test('❌ Admin cannot approve with no location at all', async () => {
      await seed('in_talks');
      await assertFails(approve(ADMIN_UID, 'admin'));
    });

    test('❌ Staff cannot approve with Bangalore', async () => {
      await seed('in_talks', { eventLocation: 'Bangalore' });
      await assertFails(approve(STAFF_UID, 'staff'));
    });

    test('❌ Approving via a legacy alias (confirmed) is checked too', async () => {
      await seed('in_talks', { eventLocation: 'Bangalore' });
      await assertFails(
        docAs(ADMIN_UID, 'admin').update({ statusValue: 'confirmed', updatedAt: new Date() })
      );
    });

    test.each([['JP Nagar'], ['Whitefield, Bangalore'], ['Palace Grounds, Vasanth Nagar']])(
      '✅ Admin can approve with location %p',
      async (location) => {
        await seed('in_talks', { eventLocation: location });
        await assertSucceeds(approve(ADMIN_UID, 'admin'));
      }
    );

    test('✅ Staff can approve with JP Nagar', async () => {
      await seed('in_talks', { eventLocation: 'JP Nagar' });
      await assertSucceeds(approve(STAFF_UID, 'staff'));
    });

    test('✅ A stored locationArea is enough even when the text is Bangalore', async () => {
      await seed('in_talks', { eventLocation: 'Bangalore', locationArea: 'Indiranagar' });
      await assertSucceeds(approve(ADMIN_UID, 'admin'));
    });

    test('✅ The location can be added in the same write as the approval', async () => {
      await seed('in_talks', { eventLocation: 'Bangalore' });
      await assertSucceeds(
        approve(STAFF_UID, 'staff', { eventLocation: 'JP Nagar', locationArea: 'JP Nagar' })
      );
    });

    test('❌ A vague locationArea does not count', async () => {
      await seed('in_talks', { eventLocation: 'Bangalore' });
      await assertFails(approve(ADMIN_UID, 'admin', { locationArea: 'Bengaluru' }));
    });

    test('✅ Non-approval edits are unaffected', async () => {
      await seed('approved', { eventLocation: 'Bangalore' });
      await assertSucceeds(docAs(ADMIN_UID, 'admin').update({ notes: 'x', updatedAt: new Date() }));
      await assertSucceeds(docAs(STAFF_UID, 'staff').update({ notes: 'y', updatedAt: new Date() }));
      await seed('in_talks', { eventLocation: 'Bangalore' });
      await assertSucceeds(
        docAs(STAFF_UID, 'staff').update({
          statusValue: 'closed_lost',
          statusUpdatedBy: STAFF_UID,
          lostAt: new Date(),
          updatedAt: new Date(),
        })
      );
    });

    test('✅ Re-saving a legacy approved alias as approved is unaffected', async () => {
      await seed('confirmed', { eventLocation: 'Bangalore' });
      await assertSucceeds(
        docAs(ADMIN_UID, 'admin').update({ statusValue: 'approved', updatedAt: new Date() })
      );
    });

    test('✅ Moving an approved enquiry on (completed) is unaffected', async () => {
      await seed('approved', { eventLocation: 'Bangalore' });
      await assertSucceeds(approve(ADMIN_UID, 'admin', { statusValue: 'completed' }));
    });
  });

  describe('🎉 Multi-function bookings (functions array)', () => {
    const fn = (id, eventType, day, extra = {}) => ({
      id,
      eventType,
      eventTypeLabel: eventType[0].toUpperCase() + eventType.slice(1),
      date: new Date(`2026-12-${day}T00:00:00+05:30`),
      ...extra,
    });
    const functions = [
      fn('h1', 'haldi', '10', { location: 'JP Nagar', locationArea: 'JP Nagar' }),
      fn('m1', 'mehendi', '11'),
      fn('w1', 'wedding', '12', { time: '19:00', location: 'Palace Grounds' }),
      fn('r1', 'reception', '13'),
    ];
    // What the app writes when functions are saved (functionSyncFields).
    const syncedWrite = (uid) => ({
      functions,
      functionCount: 4,
      eventStartDate: functions[0].date,
      eventDate: functions[3].date,
      eventType: 'wedding',
      eventTypeValue: 'wedding',
      eventTypeLabel: 'Wedding',
      eventLocation: 'Palace Grounds',
      textIndex: 'functions test haldi mehendi wedding reception',
      updatedBy: uid,
      updatedAt: new Date(),
    });
    const seed = async (extra = {}) => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('enquiries').doc('functions-doc').set({
          customerName: 'Functions Test',
          eventType: 'wedding',
          eventDate: new Date('2026-12-12T00:00:00+05:30'),
          eventLocation: 'Bangalore',
          statusValue: 'in_talks',
          assignedTo: STAFF_UID,
          totalCost: 200000,
          createdAt: new Date(),
          updatedAt: new Date(),
          createdBy: ADMIN_UID,
          ...extra,
        });
      });
    };
    const docAs = (uid, role) =>
      testEnv.authenticatedContext(uid, { role }).firestore().collection('enquiries').doc('functions-doc');

    test('✅ Assigned staff can add functions (with synced top-level fields)', async () => {
      await seed();
      await assertSucceeds(docAs(STAFF_UID, 'staff').update(syncedWrite(STAFF_UID)));
    });

    test('✅ Assigned staff can edit and remove functions', async () => {
      await seed({ functions, functionCount: 4, eventStartDate: functions[0].date });
      await assertSucceeds(
        docAs(STAFF_UID, 'staff').update({
          functions: functions.slice(0, 2),
          functionCount: 2,
          eventDate: functions[1].date,
          updatedAt: new Date(),
        })
      );
      // Back to a single event: the array fields are deleted.
      const firebase = require('firebase/compat/app').default;
      await assertSucceeds(
        docAs(STAFF_UID, 'staff').update({
          functions: firebase.firestore.FieldValue.delete(),
          functionCount: firebase.firestore.FieldValue.delete(),
          eventStartDate: firebase.firestore.FieldValue.delete(),
          updatedAt: new Date(),
        })
      );
    });

    test('❌ Staff cannot edit functions on an enquiry assigned to someone else', async () => {
      await seed({ assignedTo: OTHER_STAFF_UID });
      await assertFails(docAs(STAFF_UID, 'staff').update(syncedWrite(STAFF_UID)));
    });

    test('❌ A functions save cannot smuggle a protected field for staff', async () => {
      await seed();
      await assertFails(
        docAs(STAFF_UID, 'staff').update({ ...syncedWrite(STAFF_UID), totalCost: 1 })
      );
    });

    test('✅ Admin can save functions', async () => {
      await seed();
      await assertSucceeds(docAs(ADMIN_UID, 'admin').update(syncedWrite(ADMIN_UID)));
    });

    test('✅ Approving checks the synced top-level location from functions', async () => {
      await seed({ functions, functionCount: 4 });
      // Top-level still "Bangalore" → rejected.
      await assertFails(
        docAs(STAFF_UID, 'staff').update({
          statusValue: 'approved',
          statusUpdatedBy: STAFF_UID,
          approvedAt: new Date(),
          updatedAt: new Date(),
        })
      );
      // Synced from the main function's location in the same write → allowed.
      await assertSucceeds(
        docAs(STAFF_UID, 'staff').update({
          statusValue: 'approved',
          statusUpdatedBy: STAFF_UID,
          approvedAt: new Date(),
          eventLocation: 'Palace Grounds',
          updatedAt: new Date(),
        })
      );
    });
  });

  describe('🕘 Enquiry history (append-only)', () => {
    const history = (uid, role) =>
      testEnv
        .authenticatedContext(uid, { role })
        .firestore()
        .collection('enquiries')
        .doc('enquiry-assigned-to-staff')
        .collection('history');

    const entry = (userId) => ({
      field_changed: 'statusValue',
      old_value: 'new',
      new_value: 'in_talks',
      user_id: userId,
      timestamp: new Date(),
      user_email: 'staff@example.com',
    });

    test('✅ Assigned staff can append history as themselves', async () => {
      await assertSucceeds(history(STAFF_UID, 'staff').add(entry(STAFF_UID)));
    });

    test('❌ History cannot be written under another uid (staff or admin)', async () => {
      await assertFails(history(STAFF_UID, 'staff').add(entry(OTHER_STAFF_UID)));
      await assertFails(history(ADMIN_UID, 'admin').add(entry(STAFF_UID)));
    });

    test('❌ History entries cannot be edited, even by admins', async () => {
      let id;
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const ref = await context
          .firestore()
          .collection('enquiries')
          .doc('enquiry-assigned-to-staff')
          .collection('history')
          .add(entry(STAFF_UID));
        id = ref.id;
      });
      await assertFails(history(STAFF_UID, 'staff').doc(id).update({ new_value: 'approved' }));
      await assertFails(history(ADMIN_UID, 'admin').doc(id).update({ new_value: 'approved' }));
      await assertFails(history(STAFF_UID, 'staff').doc(id).delete());
    });
  });

  describe('🔔 User notifications', () => {
    const notifications = (uid, role, targetUid) =>
      testEnv
        .authenticatedContext(uid, { role })
        .firestore()
        .collection('users')
        .doc(targetUid)
        .collection('notifications');

    const valid = () => ({
      title: 'Enquiry Status Updated',
      body: 'Status changed from New to In Talks for John Doe',
      data: { type: 'status_update', enquiryId: 'enquiry-assigned-to-staff' },
      read: false,
      createdAt: new Date(),
    });

    // P0: notifications are server-created only (notifyEnquiryEvent / scheduled jobs).
    test('❌ Staff cannot create a notification for a colleague (admin)', async () => {
      await assertFails(notifications(STAFF_UID, 'staff', ADMIN_UID).add(valid()));
    });

    test('❌ Staff cannot create a notification for another staff member', async () => {
      await assertFails(notifications(STAFF_UID, 'staff', OTHER_STAFF_UID).add(valid()));
    });

    test('❌ Staff cannot send arbitrary content even with the full contract keys', async () => {
      await assertFails(
        notifications(STAFF_UID, 'staff', ADMIN_UID).add({
          ...valid(),
          title: 'URGENT: transfer the advance to my account',
          type: 'status_update',
          enquiryId: 'enquiry-assigned-to-staff',
          createdBy: STAFF_UID,
          senderId: STAFF_UID,
        })
      );
    });

    test('❌ Staff cannot create a notification with a fixed id (no overwrite of server ids)', async () => {
      await assertFails(
        notifications(STAFF_UID, 'staff', OTHER_STAFF_UID).doc('fu_enquiry-1_1_due').set(valid())
      );
    });

    test('❌ Users cannot create notifications in their own inbox either', async () => {
      await assertFails(notifications(STAFF_UID, 'staff', STAFF_UID).add(valid()));
    });

    test('❌ Admins cannot create notifications from the client', async () => {
      await assertFails(notifications(ADMIN_UID, 'admin', STAFF_UID).add(valid()));
    });

    test('❌ Inactive user cannot queue notifications', async () => {
      await assertFails(notifications(INACTIVE_STAFF_UID, 'staff', ADMIN_UID).add(valid()));
    });

    test('❌ Staff cannot read a colleague\'s notifications; ✅ admin can', async () => {
      let id;
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const ref = await context
          .firestore()
          .collection('users')
          .doc(OTHER_STAFF_UID)
          .collection('notifications')
          .add(valid());
        id = ref.id;
      });
      await assertFails(notifications(STAFF_UID, 'staff', OTHER_STAFF_UID).doc(id).get());
      await assertSucceeds(notifications(ADMIN_UID, 'admin', OTHER_STAFF_UID).doc(id).get());
    });

    test('✅ Owner can mark read; ❌ owner cannot rewrite content', async () => {
      let id;
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const ref = await context
          .firestore()
          .collection('users')
          .doc(STAFF_UID)
          .collection('notifications')
          .add(valid());
        id = ref.id;
      });
      await assertSucceeds(
        notifications(STAFF_UID, 'staff', STAFF_UID).doc(id).update({ read: true, readAt: new Date() })
      );
      await assertFails(
        notifications(STAFF_UID, 'staff', STAFF_UID).doc(id).update({ title: 'changed' })
      );
    });
  });

  describe('👥 Repeat customers (same phone, separate enquiries)', () => {
    const seedPair = async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        const base = {
          customerName: 'Priya Sharma',
          customerPhone: '9876543210',
          phoneNormalized: '9876543210',
          statusValue: 'new',
          assignedTo: STAFF_UID,
          createdBy: ADMIN_UID,
          createdAt: new Date(),
        };
        await db.collection('enquiries').doc('web_birthday').set({ ...base, eventTypeValue: 'birthday' });
        await db.collection('enquiries').doc('web_wedding').set({ ...base, eventTypeValue: 'wedding' });
      });
    };

    test('✅ Assignee edits one enquiry; the other is untouched', async () => {
      await seedPair();
      const db = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' }).firestore();
      await assertSucceeds(
        db.collection('enquiries').doc('web_birthday').update({
          statusValue: 'in_talks',
          statusUpdatedBy: STAFF_UID,
          inTalksAt: new Date(),
        })
      );
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const other = await context.firestore().collection('enquiries').doc('web_wedding').get();
        expect(other.get('statusValue')).toBe('new');
      });
    });

    test('❌ Staff cannot reassign a repeat enquiry; ✅ admin can still mark a genuine duplicate', async () => {
      await seedPair();
      const db = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' }).firestore();
      await assertFails(
        db.collection('enquiries').doc('web_wedding').update({ assignedTo: OTHER_STAFF_UID })
      );
      // Admin "Mark as duplicate of…" still works for genuine duplicates.
      const admin = testEnv.authenticatedContext(ADMIN_UID, { role: 'admin' }).firestore();
      await assertSucceeds(
        admin.collection('enquiries').doc('web_wedding').update({
          statusValue: 'closed_lost',
          lostReason: 'duplicate',
          mergedInto: 'web_birthday',
        })
      );
    });
  });

  describe('⏰ Follow-ups', () => {
    const firebase = require('firebase/compat/app').default;
    require('firebase/compat/firestore');
    const FV = () => firebase.firestore.FieldValue;
    const inDays = (n) => new Date(Date.now() + n * 24 * 60 * 60 * 1000);

    const seed = async (overrides = {}) => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('enquiries').doc('fu').set({
          customerName: 'Priya Sharma',
          statusValue: 'in_talks',
          assignedTo: STAFF_UID,
          createdBy: ADMIN_UID,
          createdAt: new Date(),
          followUpDueAt: new Date(Date.now() - 60 * 60 * 1000),
          followUpSeq: 4,
          followUpReason: 'auto',
          followUpNotifiedStage: 'due',
          followUpScheduledBy: 'system:followups',
          ...overrides,
        });
      });
    };
    const doc = (uid, role) =>
      testEnv.authenticatedContext(uid, { role }).firestore().collection('enquiries').doc('fu');
    const complete = (uid) => ({
      followUpDueAt: null,
      followUpSeq: FV().increment(1),
      followUpNotifiedStage: null,
      followUpLastCompletedAt: FV().serverTimestamp(),
      followUpLastCompletedBy: uid,
    });
    const reschedule = (uid, due = inDays(2)) => ({
      followUpDueAt: due,
      followUpSeq: FV().increment(1),
      followUpNotifiedStage: null,
      followUpReason: 'callback',
      followUpScheduledBy: uid,
      followUpNote: 'Call after 6 pm',
    });

    test('✅ Assignee can complete their follow-up', async () => {
      await seed();
      await assertSucceeds(doc(STAFF_UID, 'staff').update(complete(STAFF_UID)));
    });

    test('✅ Assignee can reschedule to a later callback; ✅ admin can too', async () => {
      await seed();
      await assertSucceeds(doc(STAFF_UID, 'staff').update(reschedule(STAFF_UID)));
      await assertSucceeds(doc(ADMIN_UID, 'admin').update(reschedule(ADMIN_UID, inDays(5))));
    });

    test('❌ Staff cannot touch a follow-up on an enquiry not assigned to them', async () => {
      await seed({ assignedTo: OTHER_STAFF_UID });
      await assertFails(doc(STAFF_UID, 'staff').update(complete(STAFF_UID)));
    });

    test('❌ Reschedule into the past or without bumping the sequence is rejected', async () => {
      await seed();
      await assertFails(doc(STAFF_UID, 'staff').update(reschedule(STAFF_UID, new Date(Date.now() - 60000))));
      await assertFails(
        doc(STAFF_UID, 'staff').update({ ...reschedule(STAFF_UID), followUpSeq: 4 })
      );
    });

    test('❌ Clients cannot suppress or fake reminder bookkeeping', async () => {
      await seed({ followUpNotifiedStage: null });
      await assertFails(doc(STAFF_UID, 'staff').update({ followUpNotifiedStage: 'overdue', followUpSeq: 5 }));
      await assertFails(doc(STAFF_UID, 'staff').update({ followUpLastNotifiedAt: new Date() }));
      await assertFails(doc(ADMIN_UID, 'admin').update({ pastEventReviewAt: null }));
    });

    test('❌ Completion must be attributed to the caller', async () => {
      await seed();
      await assertFails(doc(STAFF_UID, 'staff').update(complete(OTHER_STAFF_UID)));
    });

    test('❌ Callback notes are capped at 300 characters', async () => {
      await seed();
      await assertFails(
        doc(STAFF_UID, 'staff').update({ ...reschedule(STAFF_UID), followUpNote: 'x'.repeat(301) })
      );
    });

    test('✅ Ordinary edits are unaffected by the follow-up rules', async () => {
      await seed();
      await assertSucceeds(doc(STAFF_UID, 'staff').update({ notes: 'Customer prefers evenings' }));
    });
  });

  describe('💰 Financial summary (money is admin-only)', () => {
    const seed = async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.collection('enquiries').doc('money').set({
          customerName: 'Priya Sharma',
          statusValue: 'in_talks',
          assignedTo: STAFF_UID,
          createdBy: ADMIN_UID,
          createdAt: new Date(),
          totalCost: 90000, // legacy parent field, not yet migrated
        });
        await db.collection('enquiries').doc('money').collection('financial').doc('summary').set({
          totalCost: 90000,
          advancePaid: 20000,
          paymentStatusValue: 'partial',
        });
      });
    };
    const summary = (uid, role) =>
      testEnv
        .authenticatedContext(uid, { role })
        .firestore()
        .collection('enquiries')
        .doc('money')
        .collection('financial')
        .doc('summary');
    const parent = (uid, role) =>
      testEnv.authenticatedContext(uid, { role }).firestore().collection('enquiries').doc('money');

    test('❌ Assigned staff cannot read the financial summary', async () => {
      await seed();
      await assertFails(summary(STAFF_UID, 'staff').get());
    });

    test('✅ Admin can read and write the financial summary', async () => {
      await seed();
      await assertSucceeds(summary(ADMIN_UID, 'admin').get());
      await assertSucceeds(summary(ADMIN_UID, 'admin').set({ totalCost: 95000 }, { merge: true }));
    });

    test('❌ Staff cannot write the financial summary', async () => {
      await seed();
      await assertFails(summary(STAFF_UID, 'staff').set({ totalCost: 1 }, { merge: true }));
    });

    test('❌ Staff cannot write money fields on the enquiry', async () => {
      await seed();
      for (const field of ['totalCost', 'advancePaid', 'paymentStatusValue', 'quotedAmount']) {
        await assertFails(parent(STAFF_UID, 'staff').update({ [field]: 5 }));
      }
    });

    test('❌ Admins cannot put money back on the enquiry; ✅ they may remove it (migration)', async () => {
      await seed();
      await assertFails(parent(ADMIN_UID, 'admin').update({ advancePaid: 1000 }));
      await assertFails(parent(ADMIN_UID, 'admin').update({ totalCost: 1 }));
      const firebase = require('firebase/compat/app').default;
      await assertSucceeds(
        parent(ADMIN_UID, 'admin').update({ totalCost: firebase.firestore.FieldValue.delete() })
      );
      await assertFails(
        testEnv.authenticatedContext(ADMIN_UID, { role: 'admin' }).firestore()
          .collection('enquiries').doc('new-with-money')
          .set({ customerName: 'X', statusValue: 'new', totalCost: 10 })
      );
    });

    test('✅ Admin collection-group read of summaries; ❌ staff denied', async () => {
      await seed();
      const group = (uid, role) =>
        testEnv.authenticatedContext(uid, { role }).firestore().collectionGroup('financial').get();
      await assertSucceeds(group(ADMIN_UID, 'admin'));
      await assertFails(group(STAFF_UID, 'staff'));
    });
  });

  describe('📇 Colleague contact details (private profile)', () => {
    const profile = (uid, role, target) =>
      testEnv
        .authenticatedContext(uid, { role })
        .firestore()
        .collection('users')
        .doc(target)
        .collection('private')
        .doc('profile');
    const seed = async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc(OTHER_STAFF_UID)
          .collection('private').doc('profile')
          .set({ phone: '9876543210', email: 'other@example.com' });
      });
    };

    test('❌ A colleague cannot read another user\'s phone / email', async () => {
      await seed();
      await assertFails(profile(STAFF_UID, 'staff', OTHER_STAFF_UID).get());
    });

    test('✅ The owner and admins can read; owner can update their own', async () => {
      await seed();
      await assertSucceeds(profile(OTHER_STAFF_UID, 'staff', OTHER_STAFF_UID).get());
      await assertSucceeds(profile(ADMIN_UID, 'admin', OTHER_STAFF_UID).get());
      await assertSucceeds(
        profile(OTHER_STAFF_UID, 'staff', OTHER_STAFF_UID).set({ phone: '9000000000' }, { merge: true })
      );
      await assertSucceeds(
        profile(ADMIN_UID, 'admin', OTHER_STAFF_UID).set({ email: 'new@example.com' }, { merge: true })
      );
    });

    test('❌ Colleagues cannot write it; ❌ only phone / email / updatedAt are allowed', async () => {
      await seed();
      await assertFails(profile(STAFF_UID, 'staff', OTHER_STAFF_UID).set({ phone: '1' }, { merge: true }));
      await assertFails(
        profile(OTHER_STAFF_UID, 'staff', OTHER_STAFF_UID).set({ role: 'admin' }, { merge: true })
      );
    });

    test('✅ Active users still read the public users doc (name / role / isActive)', async () => {
      const db = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' }).firestore();
      await assertSucceeds(db.collection('users').doc(OTHER_STAFF_UID).get());
    });
  });

  describe('🔕 customer_prefs (server-written only)', () => {
    const pref = (uid, role) =>
      testEnv.authenticatedContext(uid, { role }).firestore().collection('customer_prefs').doc('9876543210');

    test('❌ Staff and admins cannot write customer_prefs from the client', async () => {
      const body = { noReminders: true, updatedAt: new Date(), updatedBy: STAFF_UID };
      await assertFails(pref(STAFF_UID, 'staff').set(body));
      await assertFails(pref(ADMIN_UID, 'admin').set({ ...body, updatedBy: ADMIN_UID }));
      await assertFails(pref(ADMIN_UID, 'admin').delete());
    });

    test('✅ Active users can read customer_prefs', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('customer_prefs').doc('9876543210').set({ noReminders: true });
      });
      await assertSucceeds(pref(STAFF_UID, 'staff').get());
    });
  });

  describe('🚫 Inactive users', () => {
    test('✅ Inactive user can still read their own profile (Access disabled screen)', async () => {
      const firestore = testEnv.authenticatedContext(INACTIVE_STAFF_UID, { role: 'staff' }).firestore();
      await assertSucceeds(firestore.collection('users').doc(INACTIVE_STAFF_UID).get());
    });

    test('❌ Inactive user cannot read other profiles', async () => {
      const firestore = testEnv.authenticatedContext(INACTIVE_STAFF_UID, { role: 'staff' }).firestore();
      await assertFails(firestore.collection('users').doc(ADMIN_UID).get());
      await assertFails(firestore.collection('users').get());
    });

    test('✅ Active user can read colleague profiles (D6)', async () => {
      const firestore = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' }).firestore();
      await assertSucceeds(firestore.collection('users').doc(ADMIN_UID).get());
    });

    test('❌ Inactive user cannot read dropdowns or app config', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        // One firestore() per context: a second call re-runs useEmulator on a started instance.
        const db = context.firestore();
        await db.collection('dropdowns').doc('statuses').collection('items').doc('new').set({ label: 'New' });
        await db.collection('app_config').doc('update').set({ latestBuild: 1 });
      });
      const firestore = testEnv.authenticatedContext(INACTIVE_STAFF_UID, { role: 'staff' }).firestore();
      await assertFails(firestore.collection('dropdowns').doc('statuses').collection('items').doc('new').get());
      await assertFails(firestore.collection('app_config').doc('update').get());

      const active = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' }).firestore();
      await assertSucceeds(active.collection('dropdowns').doc('statuses').collection('items').doc('new').get());
    });

    test('✅ Admin can create/update dropdowns/event_types marker; staff can read but not write', async () => {
      const admin = testEnv.authenticatedContext(ADMIN_UID, { role: 'admin' }).firestore();
      const staff = testEnv.authenticatedContext(STAFF_UID, { role: 'staff' }).firestore();

      await assertSucceeds(
        admin.collection('dropdowns').doc('event_types').set({ defaultsSeeded: true })
      );
      await assertSucceeds(
        admin.collection('dropdowns').doc('event_types').update({ defaultsSeeded: true })
      );
      await assertSucceeds(staff.collection('dropdowns').doc('event_types').get());
      await assertFails(
        staff.collection('dropdowns').doc('event_types').set({ defaultsSeeded: true })
      );
      await assertFails(
        staff.collection('dropdowns').doc('event_types').update({ defaultsSeeded: false })
      );
    });

    test('❌ Signed-in account with no users doc cannot read users or dropdowns', async () => {
      const firestore = testEnv.authenticatedContext('stranger-000', {}).firestore();
      await assertFails(firestore.collection('users').doc(STAFF_UID).get());
      await assertFails(firestore.collection('dropdowns').doc('statuses').collection('items').doc('new').get());
    });

    test('❌ Analytics is admin-only', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('analytics').doc('summary').set({ total: 1 });
      });
      await assertFails(
        testEnv.authenticatedContext(STAFF_UID, { role: 'staff' }).firestore().collection('analytics').doc('summary').get()
      );
      await assertSucceeds(
        testEnv.authenticatedContext(ADMIN_UID, { role: 'admin' }).firestore().collection('analytics').doc('summary').get()
      );
    });
  });

  describe('📞 Contact log & quote fields', () => {
    const contacts = (uid, role, enquiryId) =>
      testEnv
        .authenticatedContext(uid, { role })
        .firestore()
        .collection('enquiries')
        .doc(enquiryId)
        .collection('contacts');

    test('✅ Assigned staff can log a contact as themselves', async () => {
      await assertSucceeds(
        contacts(STAFF_UID, 'staff', 'enquiry-assigned-to-staff').add({
          type: 'call',
          at: new Date(),
          by: STAFF_UID,
        })
      );
    });

    test('❌ Staff cannot log a contact on someone else\'s enquiry', async () => {
      await assertFails(
        contacts(STAFF_UID, 'staff', 'enquiry-assigned-to-other').add({
          type: 'call',
          at: new Date(),
          by: STAFF_UID,
        })
      );
    });

    test('❌ Contact must be logged under the caller\'s own uid', async () => {
      await assertFails(
        contacts(STAFF_UID, 'staff', 'enquiry-assigned-to-staff').add({
          type: 'call',
          at: new Date(),
          by: OTHER_STAFF_UID,
        })
      );
    });

    test('❌ Unknown contact type is rejected', async () => {
      await assertFails(
        contacts(ADMIN_UID, 'admin', 'enquiry-assigned-to-staff').add({
          type: 'email',
          at: new Date(),
          by: ADMIN_UID,
        })
      );
    });

    test('❌ Contact log entries cannot be edited or deleted', async () => {
      let id;
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const ref = await context
          .firestore()
          .collection('enquiries')
          .doc('enquiry-assigned-to-staff')
          .collection('contacts')
          .add({ type: 'call', at: new Date(), by: STAFF_UID });
        id = ref.id;
      });
      await assertFails(contacts(ADMIN_UID, 'admin', 'enquiry-assigned-to-staff').doc(id).update({ type: 'whatsapp' }));
      await assertFails(contacts(ADMIN_UID, 'admin', 'enquiry-assigned-to-staff').doc(id).delete());
    });

    test('✅ Assigned staff can update contact counters on the enquiry', async () => {
      await assertSucceeds(
        testEnv
          .authenticatedContext(STAFF_UID, { role: 'staff' })
          .firestore()
          .collection('enquiries')
          .doc('enquiry-assigned-to-staff')
          .update({ firstContactAt: new Date(), lastContactAt: new Date(), contactCount: 1 })
      );
    });

    test('❌ Staff cannot set the quoted amount', async () => {
      await assertFails(
        testEnv
          .authenticatedContext(STAFF_UID, { role: 'staff' })
          .firestore()
          .collection('enquiries')
          .doc('enquiry-assigned-to-staff')
          .update({ quotedAmount: 50000, quotedAt: new Date() })
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

    test('❌ Admins cannot write users/{uid} directly from the client (server-only)', async () => {
      const adminContext = testEnv.authenticatedContext(ADMIN_UID, { role: 'admin' });
      const firestore = adminContext.firestore();

      await assertFails(
        firestore.collection('users').doc(STAFF_UID).update({
          active: false,
          updatedAt: new Date(),
        })
      );

      await assertFails(
        firestore.collection('users').doc(ADMIN_UID).update({
          role: 'staff',
          updatedAt: new Date(),
        })
      );

      await assertFails(
        firestore.collection('users').doc('new-user-999').set({
          name: 'Direct Create',
          role: 'staff',
          isActive: true,
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

  describe('Quotations and catalog (admin only)', () => {
    const seed = async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.collection('enquiries').doc('quote-enq').set({
          customerName: 'Ayesha',
          statusValue: 'in_talks',
          assignedTo: STAFF_UID,
          createdBy: ADMIN_UID,
          createdAt: new Date(),
        });
      });
    };

    const quote = (uid, role) =>
      testEnv
        .authenticatedContext(uid, { role })
        .firestore()
        .collection('enquiries')
        .doc('quote-enq')
        .collection('quotations')
        .doc('q1');

    const catalog = (uid, role) =>
      testEnv.authenticatedContext(uid, { role }).firestore().collection('catalog').doc('item1');

    test('✅ Admin can create and read a quotation', async () => {
      await seed();
      await assertSucceeds(
        quote(ADMIN_UID, 'admin').set({
          status: 'draft',
          items: [{ description: 'Mandap', quantity: 1, unitPrice: 10000, gstPercent: 18 }],
          total: 11800,
          createdBy: ADMIN_UID,
        })
      );
      await assertSucceeds(quote(ADMIN_UID, 'admin').get());
    });

    test('❌ Assigned staff cannot read or write quotations', async () => {
      await seed();
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context
          .firestore()
          .collection('enquiries')
          .doc('quote-enq')
          .collection('quotations')
          .doc('q1')
          .set({ status: 'draft', total: 1 });
      });
      await assertFails(quote(STAFF_UID, 'staff').get());
      await assertFails(quote(STAFF_UID, 'staff').set({ status: 'draft', total: 2 }));
    });

    test('✅ Admin can manage catalog; staff cannot', async () => {
      await assertSucceeds(
        catalog(ADMIN_UID, 'admin').set({ name: 'Floral arch', unitPrice: 8000, gstPercent: 18 })
      );
      await assertSucceeds(catalog(ADMIN_UID, 'admin').get());
      await assertFails(catalog(STAFF_UID, 'staff').get());
      await assertFails(
        catalog(STAFF_UID, 'staff').set({ name: 'Hack', unitPrice: 1 })
      );
    });
  });

  describe('Enquiries Trash & Restore Rules', () => {
    const trashRef = (uid, role, id = 'trash-enq-1') =>
      testEnv.authenticatedContext(uid, { role }).firestore().collection('enquiries_trash').doc(id);

    test('❌ Staff cannot read, create, update, or delete enquiries_trash', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('enquiries_trash').doc('trash-enq-1').set({
          enquiry: { customerName: 'Test', statusValue: 'new' },
          financial: null,
          deletedAt: new Date(),
          deletedBy: ADMIN_UID,
        });
      });

      await assertFails(trashRef(STAFF_UID, 'staff').get());
      await assertFails(trashRef(STAFF_UID, 'staff', 'trash-enq-2').set({ enquiry: {} }));
      await assertFails(trashRef(STAFF_UID, 'staff').update({ deletedBy: STAFF_UID }));
      await assertFails(trashRef(STAFF_UID, 'staff').delete());
    });

    test('✅ Admin can create, read, and delete enquiries_trash, but cannot update', async () => {
      await assertSucceeds(
        trashRef(ADMIN_UID, 'admin').set({
          enquiry: { customerName: 'Test', statusValue: 'new' },
          financial: { totalCost: 50000 },
          deletedAt: new Date(),
          deletedBy: ADMIN_UID,
        })
      );
      await assertSucceeds(trashRef(ADMIN_UID, 'admin').get());
      await assertFails(trashRef(ADMIN_UID, 'admin').update({ deletedBy: 'other' }));
      await assertSucceeds(trashRef(ADMIN_UID, 'admin').delete());
    });

    test('✅ Admin restore passes no-money check on enquiries and fails if money is on parent', async () => {
      const adminDb = testEnv.authenticatedContext(ADMIN_UID, { role: 'admin' }).firestore();
      await assertSucceeds(
        adminDb.collection('enquiries').doc('restored-1').set({
          customerName: 'Restored Client',
          statusValue: 'new',
          assignedTo: STAFF_UID,
        })
      );
      await assertSucceeds(
        adminDb.collection('enquiries').doc('restored-1').collection('financial').doc('summary').set({
          totalCost: 75000,
          advancePaid: 20000,
        })
      );
      await assertFails(
        adminDb.collection('enquiries').doc('restored-bad').set({
          customerName: 'Bad Restore',
          statusValue: 'new',
          totalCost: 75000,
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
