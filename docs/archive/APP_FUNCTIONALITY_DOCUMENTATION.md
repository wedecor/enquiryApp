# We Decor Enquiries - Complete Functionality Documentation

## Table of Contents
1. [Overview](#overview)
2. [Authentication & User Management](#authentication--user-management)
3. [Dashboard](#dashboard)
4. [Enquiry Management](#enquiry-management)
5. [Filtering & Search](#filtering--search)
6. [Admin Features](#admin-features)
7. [Analytics & Reporting](#analytics--reporting)
8. [Settings & Preferences](#settings--preferences)
9. [Notifications](#notifications)
10. [Data Export](#data-export)
11. [Audit Trail & History](#audit-trail--history)
12. [Image Management](#image-management)
13. [Role-Based Access Control](#role-based-access-control)

---

## Overview

**We Decor Enquiries** is a comprehensive Flutter-based web and mobile application for managing event decoration enquiries. The app provides a complete CRM solution for tracking customer enquiries, managing staff assignments, monitoring financials, and generating analytics reports.

### Key Technologies
- **Frontend**: Flutter (Web & Mobile)
- **Backend**: Firebase (Firestore, Authentication, Storage, Cloud Messaging)
- **State Management**: Riverpod
- **Architecture**: Clean Architecture (Presentation, Domain, Data layers)

---

## Authentication & User Management

### User Roles

The application supports two user roles:

1. **Admin**
   - Full system access
   - Can manage all enquiries regardless of assignment
   - Access to user management, analytics, and system settings
   - Can modify dropdown configurations
   - Access to financial data in exports

2. **Staff**
   - Limited access to assigned enquiries only
   - Cannot access admin features
   - Restricted financial data visibility in exports
   - Can create and update enquiries assigned to them

### Authentication Features

#### Login Screen
- **Email/Password Authentication**: Standard Firebase Authentication
- **Session Management**: Automatic session persistence
- **Role Verification**: Real-time role checking from Firestore
- **Session State Tracking**: Monitors authentication state changes

#### User Profile Management
- **Profile Viewing**: View own profile information
- **Role Display**: Shows current user role (Admin/Staff)
- **Email Verification**: Display email verification status
- **User ID Display**: Shows unique user identifier

### User Management (Admin Only)

#### User List View
- **Search Functionality**: Search users by name or email
- **Role Filtering**: Filter users by role (Admin/Staff/All)
- **Status Filtering**: Filter by active/inactive status
- **Pagination**: Load more users with pagination support
- **Layout Options**: Table view and card view layouts

#### User Operations
- **Add User**: Create new user accounts manually
  - Name, Email, Phone, Role assignment
  - Automatic Firebase Auth account creation
  - Firestore user document creation
  
- **Invite User**: Send email invitations
  - Email-based invitation system
  - Automatic account setup on acceptance
  
- **Edit User**: Modify user details
  - Update name, email, phone
  - Change role (Admin/Staff)
  - Update active status
  
- **Deactivate/Activate User**: Toggle user account status
  - Soft delete functionality
  - Preserves user data
  
- **Delete User**: Permanently remove user accounts
  - Confirmation dialog required
  - Removes from Firebase Auth and Firestore

#### User Details Display
- **User Information Card**: Shows complete user profile
- **Role Badge**: Visual indicator of user role
- **Status Indicator**: Active/Inactive status display
- **Last Login**: Track user activity (if implemented)
- **Enquiry Assignment Count**: Number of enquiries assigned

---

## Dashboard

### Dashboard Overview

The dashboard is the main landing page after login, providing a comprehensive overview of all enquiries.

#### Status Tabs
The dashboard displays enquiries organized by status tabs:
- **All**: Shows all enquiries regardless of status
- **New**: Newly created enquiries
- **In Talks**: Enquiries in discussion phase
- **Quote Sent**: Enquiries with quotes sent to customers
- **Confirmed**: Confirmed bookings
- **Not Interested**: Declined enquiries
- **Completed**: Successfully completed events
- **Cancelled**: Cancelled bookings

#### Statistics Cards
Real-time statistics displayed at the top:
- **Total Enquiries**: Count of all enquiries
- **New Enquiries**: Count of new enquiries
- **Confirmed**: Count of confirmed bookings
- **In Progress**: Count of enquiries in various active statuses
- **Revenue**: Total revenue from confirmed bookings (Admin only)

#### Search Functionality
- **Real-time Search**: Search enquiries as you type
- **Search Fields**: Searches across customer name, email, phone, event type
- **Case-Insensitive**: Search is not case-sensitive
- **Debounced Input**: Optimized search performance

#### Enquiry Cards
Each enquiry card displays:
- **Customer Name**: Primary identifier
- **Event Type**: Type of event (Wedding, Birthday, etc.)
- **Event Date**: Scheduled event date
- **Status Badge**: Color-coded status indicator
- **Priority Indicator**: Visual priority level
- **Assigned To**: Staff member assigned (if any)
- **Quick Actions**: Quick status update buttons

#### Quick Actions
- **View Details**: Navigate to full enquiry details
- **Edit**: Quick edit access (role-based)
- **Status Update**: Inline status change
- **Contact**: Quick contact options (call, email)

#### Navigation Drawer
- **Dashboard**: Return to dashboard
- **All Enquiries**: View all enquiries list
- **Analytics** (Admin only): Access analytics dashboard
- **User Management** (Admin only): Manage users
- **Dropdown Management** (Admin only): Configure dropdowns
- **Settings**: Access settings
- **Sign Out**: Logout from application

---

## Enquiry Management

### Enquiry Data Model

Each enquiry contains the following fields:

#### Customer Information
- **Customer Name** (Required): Full name of the customer
- **Customer Email**: Email address for communication
- **Customer Phone**: Contact phone number
- **Customer Name Lower**: Normalized for search (auto-generated)

#### Event Details
- **Event Type** (Required): Type of event (Wedding, Birthday, Corporate, etc.)
- **Event Date** (Required): Scheduled date of the event
- **Event Location**: Venue or location address
- **Guest Count**: Expected number of guests
- **Budget Range**: Customer's budget range
- **Description**: Detailed event description and requirements

#### Status & Assignment
- **Status** (Default: "new"): Current enquiry status
- **Priority**: Priority level (High, Medium, Low)
- **Source**: How the enquiry was received
- **Assigned To**: Staff member assigned to handle enquiry
- **Assignee Name**: Denormalized assignee name for quick display

#### Financial Information
- **Total Cost**: Total quotation amount
- **Advance Paid**: Amount paid as advance
- **Payment Status**: Payment status (Pending, Partial, Paid, etc.)

#### Metadata
- **Created At**: Timestamp of creation
- **Created By**: User ID who created the enquiry
- **Created By Name**: Denormalized creator name
- **Updated At**: Last update timestamp
- **Status Updated At**: When status was last changed
- **Status Updated By**: User who last changed status

#### Additional Fields
- **Notes**: Internal staff notes
- **Images**: Array of reference image URLs (Firebase Storage)
- **Text Index**: Searchable text index for full-text search

### Create Enquiry

#### Enquiry Form Screen
- **Form Validation**: Required field validation
- **Date Picker**: Calendar widget for event date selection
- **Dropdown Selectors**: 
  - Event Type (from dropdown configuration)
  - Status (from dropdown configuration)
  - Priority (High, Medium, Low)
  - Payment Status (Pending, Partial, Paid, etc.)
  - Assigned To (from user list)
- **Image Upload**: 
  - Select multiple images
  - Preview before upload
  - Upload to Firebase Storage
  - Support for web and mobile platforms
- **Auto-save**: Draft saving capability (if implemented)

#### Image Upload Features
- **Multiple Image Selection**: Select multiple images at once
- **Image Preview**: Preview selected images before upload
- **Image Removal**: Remove images before saving
- **Upload Progress**: Visual feedback during upload
- **Storage Organization**: Images stored in `enquiries/{enquiryId}/images/`
- **Metadata**: Content type and cache control set automatically
- **Error Handling**: Graceful error handling for failed uploads

### Edit Enquiry

#### Edit Mode Features
- **Load Existing Data**: Pre-populate form with existing enquiry data
- **Load Existing Images**: Display previously uploaded images
- **Update Fields**: Modify any enquiry field
- **Add More Images**: Upload additional reference images
- **Remove Images**: Delete existing images
- **Change History**: View what changed (via audit trail)

#### Permission Checks
- **Staff**: Can only edit enquiries assigned to them
- **Admin**: Can edit any enquiry
- **Validation**: Status transition validation

### View Enquiry Details

#### Details Screen Sections

1. **Customer Information Section**
   - Customer name, email, phone
   - Quick contact buttons (call, email, SMS)

2. **Event Details Section**
   - Event type with color-coded badge
   - Event date and location
   - Guest count and budget range
   - Full description

3. **Status & Assignment Section**
   - Current status with color badge
   - Priority level indicator
   - Assigned staff member
   - Source of enquiry

4. **Financial Information Section** (Admin only for full details)
   - Total cost
   - Advance paid
   - Payment status
   - Balance calculation

5. **Reference Images Section**
   - Grid view of uploaded images
   - Full-screen image viewer
   - Image download capability

6. **Notes Section**
   - Internal notes display
   - Add/edit notes capability

7. **Change History Section**
   - Complete audit trail
   - Who changed what and when
   - Field-level change tracking

#### Quick Actions
- **Edit**: Navigate to edit screen
- **Status Update**: Inline status change widget
- **Assign**: Change assignment
- **Delete**: Remove enquiry (with confirmation)
- **Export**: Export enquiry details

### Enquiry List Screen

#### List View Features
- **Filtering**: Advanced filter options (see Filtering section)
- **Sorting**: Sort by date, status, customer name
- **Search**: Real-time search functionality
- **Pagination**: Load more enquiries
- **Layout Options**: List view and grid view
- **Status Filtering**: Quick status-based filtering

#### Enquiry Card Display
- **Compact View**: Essential information at a glance
- **Status Strip**: Visual status indicator
- **Event Type Badge**: Color-coded event type
- **Date Display**: Formatted event date
- **Quick Actions**: Swipe actions for quick updates

---

## Filtering & Search

### Advanced Filtering System

#### Filter Categories

1. **Status Filters**
   - Multiple status selection
   - Filter by one or more statuses
   - Visual status chips

2. **Event Type Filters**
   - Filter by event type
   - Multiple selection supported
   - Color-coded event types

3. **Assignee Filter**
   - Filter by assigned staff member
   - "Unassigned" option
   - "Assigned to me" quick filter

4. **Date Range Filter**
   - Filter by event date range
   - Preset ranges (Today, This Week, This Month, etc.)
   - Custom date range picker

5. **Priority Filter**
   - Filter by priority level
   - High, Medium, Low options

6. **Source Filter**
   - Filter by enquiry source
   - Website, Phone, Referral, etc.

7. **Payment Status Filter**
   - Filter by payment status
   - Pending, Partial, Paid options

### Saved Views

#### Save Filter Presets
- **Save Current Filters**: Save current filter combination as a named view
- **View Management**: List all saved views
- **Quick Apply**: Apply saved view with one click
- **Edit Saved Views**: Modify saved filter presets
- **Delete Saved Views**: Remove saved views
- **Default View**: Set a default view to load on app start

#### Saved View Features
- **Named Views**: Give meaningful names to filter combinations
- **User-Specific**: Each user has their own saved views
- **Persistent Storage**: Saved in Firestore under user's savedViews collection
- **Quick Access**: Access saved views from filters bar

### Search Functionality

#### Search Features
- **Real-time Search**: Results update as you type
- **Multi-field Search**: Searches across:
  - Customer name
  - Customer email
  - Customer phone
  - Event type
  - Event location
  - Description
- **Case-Insensitive**: Search is not case-sensitive
- **Debounced**: Optimized performance with debouncing
- **Highlight Matches**: Highlight search terms in results (if implemented)

#### Search Integration
- **Dashboard Search**: Search from dashboard
- **List Screen Search**: Dedicated search bar in list view
- **Filter Combination**: Search works with active filters

### Filters Bar

#### Active Filters Display
- **Filter Chips**: Visual representation of active filters
- **Filter Count**: Display number of active filters
- **Remove Individual Filters**: Click to remove specific filters
- **Clear All Filters**: One-click to clear all filters
- **Show Filters Dialog**: Open advanced filters panel

---

## Admin Features

### User Management

See [Authentication & User Management](#authentication--user-management) section for detailed user management features.

### Dropdown Management

#### Purpose
Manage all dropdown options used throughout the application, including:
- Event Types
- Statuses
- Payment Statuses
- Priorities
- Sources

#### Dropdown Groups

1. **Event Types** (`event_types`)
   - Wedding, Birthday, Corporate Event, etc.
   - Each item has value, label, color, active status

2. **Statuses** (`statuses`)
   - New, In Talks, Quote Sent, Confirmed, etc.
   - Color-coded for visual identification
   - Status transition rules

3. **Payment Statuses** (`payment_statuses`)
   - Pending, Partial, Paid, Refunded, etc.

4. **Priorities** (`priorities`)
   - High, Medium, Low
   - Color-coded priority levels

5. **Sources** (`sources`)
   - Website, Phone, Referral, Social Media, etc.

#### Dropdown Item Management

**Add Dropdown Item**
- **Value**: Internal identifier (snake_case)
- **Label**: Display name
- **Color**: Hex color code or RGB
- **Active Status**: Enable/disable item
- **Order**: Display order (if implemented)

**Edit Dropdown Item**
- Modify any field
- Change active status
- Update color

**Delete Dropdown Item**
- Soft delete (mark as inactive)
- Hard delete option (with confirmation)
- Validation: Prevent deletion if in use

**Search & Filter**
- Search dropdown items
- Filter by active/inactive status
- Filter by dropdown group

#### Dropdown Features
- **Color Customization**: Each item can have custom color
- **Active/Inactive Toggle**: Enable or disable items without deletion
- **Bulk Operations**: Activate/deactivate multiple items
- **Import/Export**: Import dropdowns from CSV (if implemented)
- **Validation**: Prevent duplicate values

### System Configuration

#### App Configuration Management
- **System Settings**: Global application settings
- **Feature Flags**: Enable/disable features
- **Maintenance Mode**: Put system in maintenance mode
- **Email Templates**: Manage notification templates

---

## Analytics & Reporting

### Analytics Dashboard (Admin Only)

#### Overview Tab
- **Key Performance Indicators (KPIs)**:
  - Total Enquiries: Count of all enquiries
  - New Enquiries: Count of new enquiries this period
  - Conversion Rate: Percentage of confirmed bookings
  - Average Value: Average enquiry value
  - Total Revenue: Sum of confirmed bookings
  - Active Staff: Number of active staff members

- **Summary Cards**: Visual KPI cards with trend indicators
- **Period Comparison**: Compare current period with previous period

#### Trends Tab
- **Line Charts**: 
  - Enquiries over time
  - Revenue trends
  - Status distribution trends
  - Event type trends
  
- **Date Range Selection**: 
  - Today, This Week, This Month, This Quarter, This Year
  - Custom date range picker
  - Compare periods

- **Multiple Metrics**: Toggle between different metrics
- **Export Charts**: Export chart images (if implemented)

#### Breakdown Tab
- **Pie Charts**:
  - Enquiries by Status
  - Enquiries by Event Type
  - Enquiries by Source
  - Enquiries by Priority
  - Revenue by Event Type

- **Bar Charts**:
  - Enquiries by Staff Member
  - Enquiries by Month
  - Top Customers

- **Interactive Charts**: Click to drill down into details

#### Tables Tab
- **Top Lists**:
  - Top Customers (by enquiry count)
  - Top Staff Members (by assignment count)
  - Top Event Types
  - Top Sources

- **Detailed Tables**: 
  - Sortable columns
  - Exportable data
  - Pagination support

#### Analytics Features
- **Real-time Data**: Live data from Firestore
- **Date Filtering**: Filter analytics by date range
- **Role-based Access**: Admin-only access
- **Export Capability**: Export analytics data to CSV
- **Performance Metrics**: Track system performance

### Reporting Features

#### Report Generation
- **Custom Reports**: Create custom report templates
- **Scheduled Reports**: Schedule automatic report generation
- **Email Reports**: Email reports to stakeholders
- **PDF Export**: Export reports as PDF (if implemented)

---

## Settings & Preferences

### Settings Screen Tabs

#### Account Tab
- **User Profile**:
  - Display name, email, phone
  - User role display
  - User ID display
  
- **Account Actions**:
  - Change password
  - Update email
  - Update phone number
  - Delete account (with confirmation)

- **Account Information**:
  - Account creation date
  - Last login date
  - Email verification status

#### Preferences Tab
- **Appearance Settings**:
  - Theme mode: Light, Dark, System default
  - Color scheme customization
  - Font size preferences
  
- **Language Settings**:
  - App language selection
  - Date format preferences
  - Time format preferences
  
- **Timezone Settings**:
  - Timezone selection
  - Date/time display format

- **Save Preferences**: Save button to persist changes

#### Notifications Tab
- **Notification Preferences**:
  - Enable/disable notifications
  - Email notification preferences
  - Push notification preferences
  
- **Notification Types**:
  - New enquiry notifications
  - Assignment notifications
  - Status update notifications
  - System notifications
  
- **Notification Frequency**:
  - Real-time notifications
  - Daily digest
  - Weekly summary

#### Dashboard Defaults Tab
- **Default View**:
  - Set default status filter
  - Set default date range
  - Set default saved view
  
- **Dashboard Layout**:
  - Card size preferences
  - Items per page
  - Default sort order

#### Privacy Tab
- **Privacy Policy**: Link to privacy policy
- **Terms of Service**: Link to terms of service
- **Data Management**:
  - Data export request
  - Data deletion request
  - Cookie preferences (web)

#### Admin Tab (Admin Only)
- **System Configuration**:
  - App-wide settings
  - Feature flags
  - Maintenance mode
  
- **Data Management**:
  - Database backup
  - Data export
  - Data import
  
- **User Management**:
  - Quick access to user management
  - Role management tools

---

## Notifications

### Notification System

#### Firebase Cloud Messaging (FCM)
- **Push Notifications**: Real-time push notifications
- **Topic Subscriptions**: Subscribe to role-based topics
- **Token Management**: Automatic FCM token management
- **Multi-device Support**: Receive notifications on all devices

#### Notification Types

1. **New Enquiry Notifications**
   - Sent to all admins when new enquiry is created
   - Includes customer name and event type
   - Deep link to enquiry details

2. **Assignment Notifications**
   - Sent when enquiry is assigned to staff
   - Includes enquiry details
   - Quick action buttons

3. **Status Update Notifications**
   - Sent when enquiry status changes
   - Includes old and new status
   - Link to enquiry details

4. **System Notifications**
   - System maintenance alerts
   - Important announcements
   - Security alerts

#### Notification Features
- **In-App Notifications**: Notification center in app
- **Badge Counts**: Unread notification count
- **Mark as Read**: Mark notifications as read
- **Delete Notifications**: Remove notifications
- **Notification History**: View past notifications
- **Notification Settings**: Per-type notification preferences

#### Notification Storage
- **Firestore Storage**: Notifications stored in Firestore
- **User-Specific**: Each user has their own notification collection
- **Topic-Based**: Topic notifications stored separately
- **Read Status Tracking**: Track read/unread status

---

## Data Export

### CSV Export Functionality

#### Export Features
- **Role-Based Export**: Different fields based on user role
- **Filtered Export**: Export only filtered/visible enquiries
- **Date Range Export**: Export enquiries within date range
- **Custom Fields**: Select specific fields to export

#### Admin Export Fields
Full access export includes:
- ID, Customer Name, Email, Phone
- Event Type, Event Date, Location
- Guest Count, Budget Range, Description
- Status, Payment Status
- Total Cost, Advance Paid
- Assigned To, Priority, Source
- Staff Notes
- Created At, Created By, Updated At

#### Staff Export Fields
Limited export (no financial data):
- ID, Customer Name, Phone
- Event Type, Event Date, Location
- Guest Count, Description
- Status, Priority, Source
- Staff Notes
- Created At

#### Export Process
1. **Select Data**: Choose enquiries to export
2. **Generate CSV**: Convert data to CSV format
3. **Download File**: Download CSV file
4. **File Naming**: Auto-generated filename with timestamp
5. **Audit Logging**: Export action logged in audit trail

#### Export Options
- **File Format**: CSV (Comma-separated values)
- **Encoding**: UTF-8 encoding
- **Date Format**: ISO 8601 format
- **Delimiter**: Comma delimiter
- **Headers**: Include column headers

---

## Audit Trail & History

### Change Tracking

#### Audit Service
- **Automatic Tracking**: All changes automatically tracked
- **Field-Level Tracking**: Track changes to individual fields
- **User Attribution**: Record who made each change
- **Timestamp Recording**: Record when changes occurred

#### Change History Display

#### Enquiry History Widget
- **Complete History**: Display all changes to an enquiry
- **Chronological Order**: Changes displayed in chronological order
- **Field Changes**: Show old value → new value
- **User Information**: Display who made the change
- **Timestamp Display**: When the change occurred
- **Change Type**: Type of change (create, update, delete)

#### History Entry Details
Each history entry includes:
- **Field Changed**: Name of the field that changed
- **Old Value**: Previous value
- **New Value**: New value
- **User ID**: Who made the change
- **User Email**: Email of the user
- **Timestamp**: When the change occurred
- **Change Type**: Type of operation

#### History Features
- **Real-time Updates**: History updates in real-time
- **Filter History**: Filter by user, date, field
- **Export History**: Export change history
- **Search History**: Search through change history
- **Visual Indicators**: Color-coded change types

#### Bulk Change Tracking
- **Multiple Changes**: Track multiple field changes in one operation
- **Batch Recording**: Efficient batch recording of changes
- **Transaction Support**: Changes recorded within transactions

---

## Image Management

### Image Upload

#### Upload Features
- **Multiple Images**: Upload multiple images per enquiry
- **Image Selection**: 
  - Web: File picker
  - Mobile: Camera or gallery
- **Image Preview**: Preview before upload
- **Image Removal**: Remove images before saving
- **Upload Progress**: Visual progress indicator

#### Image Storage
- **Firebase Storage**: Images stored in Firebase Storage
- **Organized Structure**: `enquiries/{enquiryId}/images/{filename}`
- **Metadata**: Content type and cache control set
- **URL Generation**: Download URLs generated automatically

#### Image Display
- **Grid View**: Display images in grid layout
- **Full-Screen Viewer**: Tap to view full screen
- **Image Zoom**: Zoom in/out capability
- **Image Download**: Download images (if implemented)
- **Loading States**: Loading indicators while fetching
- **Error Handling**: Graceful error handling for failed loads

#### Image Management
- **Add Images**: Add more images to existing enquiry
- **Remove Images**: Delete images from enquiry
- **Replace Images**: Replace existing images
- **Image Ordering**: Reorder images (if implemented)

#### Platform Support
- **Web**: File picker with drag-and-drop support
- **Mobile**: Camera and gallery access
- **Image Formats**: Support for JPEG, PNG, WebP
- **File Size Limits**: Configurable file size limits

---

## Role-Based Access Control

### Permission System

#### Admin Permissions
- **Full Access**: Access to all enquiries
- **User Management**: Create, edit, delete users
- **Dropdown Management**: Configure dropdown options
- **Analytics Access**: View analytics dashboard
- **System Settings**: Modify system configuration
- **Financial Data**: Access to all financial information
- **Export Full Data**: Export with all fields including financials

#### Staff Permissions
- **Assigned Enquiries Only**: View/edit only assigned enquiries
- **Create Enquiries**: Can create new enquiries
- **Limited Edit**: Can edit assigned enquiries only
- **No User Management**: Cannot manage users
- **No Dropdown Management**: Cannot modify dropdowns
- **No Analytics**: Cannot access analytics
- **Limited Financial Access**: Limited financial data visibility
- **Restricted Export**: Export without financial fields

### Access Control Implementation

#### Route Guards
- **Protected Routes**: Routes protected by role checks
- **Redirect Logic**: Redirect unauthorized users
- **Permission Checks**: Check permissions before access

#### UI Element Visibility
- **Conditional Rendering**: Show/hide UI based on role
- **Feature Flags**: Enable/disable features by role
- **Action Restrictions**: Disable actions based on permissions

#### Data Filtering
- **Query Filtering**: Filter Firestore queries by role
- **Field Masking**: Hide sensitive fields from staff
- **Export Filtering**: Filter export data by role

### Security Features
- **Firestore Security Rules**: Backend security rules
- **Client-Side Validation**: Additional client-side checks
- **Audit Logging**: Log all permission-related actions
- **Session Management**: Secure session handling

---

## Additional Features

### Contact Integration
- **Phone Calls**: Direct phone call functionality
- **Email**: Send emails to customers
- **SMS**: Send SMS messages (if implemented)
- **Contact Launcher**: Native contact launcher integration

### Search & Indexing
- **Full-Text Search**: Search across multiple fields
- **Normalized Fields**: Normalized fields for efficient search
- **Search Index**: Text index for fast searching
- **Search Highlighting**: Highlight search terms in results

### Performance Optimization
- **Lazy Loading**: Load data on demand
- **Pagination**: Paginate large datasets
- **Caching**: Cache frequently accessed data
- **Debouncing**: Debounce search and filter inputs

### Error Handling
- **Graceful Degradation**: Handle errors gracefully
- **Error Messages**: User-friendly error messages
- **Retry Logic**: Retry failed operations
- **Offline Support**: Basic offline support (if implemented)

### Accessibility
- **Screen Reader Support**: Support for screen readers
- **Keyboard Navigation**: Full keyboard navigation
- **High Contrast**: High contrast mode support
- **Font Scaling**: Support for font scaling

### Internationalization
- **Multi-language Support**: Support for multiple languages
- **Date Formatting**: Locale-specific date formatting
- **Number Formatting**: Locale-specific number formatting
- **Currency Formatting**: Locale-specific currency formatting

---

## Technical Architecture

### State Management
- **Riverpod**: Primary state management solution
- **Providers**: Feature-based providers
- **Stream Providers**: Real-time data streams
- **State Notifiers**: Complex state management

### Data Layer
- **Firestore**: Primary database
- **Firebase Storage**: File storage
- **Firebase Auth**: Authentication
- **Repository Pattern**: Data access abstraction

### Presentation Layer
- **Widget Composition**: Reusable widget components
- **Screen Architecture**: Feature-based screens
- **Navigation**: Route-based navigation
- **Theme System**: Material Design 3 theming

### Domain Layer
- **Models**: Domain models with Freezed
- **Business Logic**: Core business logic
- **Validators**: Data validation logic
- **Use Cases**: Feature use cases

---

## Conclusion

This documentation covers all major functionalities of the We Decor Enquiries application. The app provides a comprehensive solution for managing event decoration enquiries with role-based access control, advanced filtering, analytics, and robust audit trails.

For specific implementation details, refer to the source code and inline documentation.

