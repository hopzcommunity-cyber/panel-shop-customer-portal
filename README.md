# Panel Shop Customer Portal

A mobile-friendly repair progress portal. Workshop staff update each vehicle once; customers sign in on their phones to see the vehicles linked to their email, the current repair stage, estimated completion date, and dated progress notes.

## Stack
- Static HTML/CSS/JavaScript hosted on Netlify
- Supabase Auth and PostgreSQL on the free tier
- Row-level security limits customer access to their own vehicles; only staff can add vehicles or edit repair updates

## One-time setup
1. In the Supabase project, open **SQL Editor → New query**, paste all of `supabase-setup.sql`, and run it.
2. Open **Authentication → URL Configuration** and add your deployed website URL to the allowed redirect URLs. Set the Site URL to the same URL.
3. Deploy this repository's root folder to Netlify (the `index.html` must be at the published root). For ongoing automatic deploys, connect this GitHub repository in Netlify's **Add new site → Import an existing project** flow and select the `main` branch.
4. Open the deployed site and create an account using the workshop owner's email. Confirm the email if Supabase asks you to.
5. In Supabase SQL Editor, promote only the trusted workshop account. Replace the email below with the exact email used to register:

```sql
update public.panel_profiles
set role = 'staff'
where lower(email) = lower('YOUR_EMAIL@example.com');
```

6. Sign out and back in. The workshop dashboard will appear. Customers can register themselves; their accounts remain customer accounts.

## Daily use
- Staff add a vehicle using the customer's exact account email.
- Staff select a repair stage, enter a note and estimated completion date, then save.
- Customers sign in to see their own vehicle progress. The portal refreshes automatically every 15 seconds or via the Refresh button.

## Security notes
- The publishable Supabase key in `index.html` is intended for browser use. **Never put a Supabase service-role or secret key in frontend code or this public repository.**
- Run the SQL setup before using the site. Test with a staff account and a separate customer account before entering real customer data.
- This starter uses repair notes and dates; customer photo uploads are not implemented yet.
- Free plans have usage and service limits that can change. A one-time database setup and Netlify connection still need to be completed in the relevant dashboards.
