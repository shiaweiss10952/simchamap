# SimchaMap Softr Organizer Setup

Use Softr as the logged-in organizer portal. The live organizer created in Softr is:

`https://organizer.simchamap.com`

Note: the current Softr app was generated with Softr's own internal database so it is usable right away. The Supabase tables are also ready if you later want to connect Softr directly to Supabase.

## 1. Run Supabase SQL

Run `supabase-vendor-admin-setup.sql` in Supabase SQL Editor.

This creates:

- `organizer_events`
- `organizer_tasks`
- `organizer_budget_items`
- `organizer_vendor_contacts`
- `organizer_calendar_items`
- `organizer_notes`
- `organizer_saved_vendors`

## 2. Connect Softr to Supabase

In Softr, add Supabase as a data source. Softr says Supabase data sources are available on Professional and higher plans.

## 3. Create Softr Pages

Recommended pages:

- Dashboard
- Checklist
- Budget
- Vendor CRM
- Calendar
- Notes
- Saved Vendors

## 4. Checklist Table Fields

Use `organizer_tasks`.

Important fields:

- `owner_email`
- `task_title`
- `category`
- `stage`
- `due_date`
- `actual_date`
- `status`
- `assigned_to`
- `vendor_name`
- `notes`

The important new field the website needs is `actual_date`.

## 5. User Privacy Filter

Every Softr block should filter records where:

`owner_email` equals the logged-in user's email.

Every create form should set:

`owner_email` to the logged-in user's email.

## 6. Connect To Website

After Softr publishes the organizer, use the organizer custom domain.

Open `dashboard.html` and set:

```js
const SOFTR_ORGANIZER_URL = 'https://organizer.simchamap.com';
```

Then upload the site again.

## 7. Add Back Link To Main Site

In Softr, add the contents of `softr-back-to-simchamap-snippet.html` to:

`Settings -> Custom Code -> Code Inside Footer`

Then publish the Softr app.

This adds a fixed `Back to SimchaMap` link on `https://organizer.simchamap.com/` that points to:

`https://simchamap.com`
