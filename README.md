<div align="center">
<br/>
<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
<img src="https://img.shields.io/badge/GetX-8E44AD?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Hive-FDB623?style=for-the-badge&logo=hive&logoColor=black" />
<img src="https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white" />
<img src="https://img.shields.io/badge/OneSignal-E54A4A?style=for-the-badge&logo=onesignal&logoColor=white" />
<img src="https://img.shields.io/badge/Google%20Maps-4285F4?style=for-the-badge&logo=googlemaps&logoColor=white" />
<br/><br/>
</div>

# ShopX — Multi-Role E-Commerce App

**ShopX** is a full-stack e-commerce app built with Flutter and Firebase, made up of **three independent Flutter apps** that share a single backend:

- **Customer App** — browse, search, order, chat with support, and track deliveries live
- **Rider App** — accept nearby delivery jobs, go out for delivery, and broadcast live location
- **Admin Panel** — manage products, categories, orders, riders, support chat, and view sales analytics from a responsive desktop-first dashboard

All three apps are **separate codebases** with their own `main.dart`, routing, and dependencies, but they all read and write to the same Firestore database in real time — so an order placed by a customer, claimed by a rider, or updated by an admin reflects instantly across every surface.

---

## Table of Contents

- [Overview](#overview)
- [Customer App — Features](#customer-app--features)
- [Rider App — Features](#rider-app--features)
- [Admin Panel — Features](#admin-panel--features)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Core Data Flows](#core-data-flows)
- [Getting Started](#getting-started)
- [Configuration Notes](#configuration-notes)
- [Firestore Security Rules](#firestore-security-rules)
- [Security Notes](#security-notes)
- [License](#license)

---

## Overview

| App | Role | State Management | Local Storage |
|---|---|---|---|
| Customer App | Browse, order, pay, track, chat | GetX | Hive (cart, favorites, orders, profile) |
| Rider App | Accept & fulfil deliveries | GetX | — (Firestore-only, no local cache) |
| Admin Panel | Manage catalog & operations | GetX | — (Firestore-only, no local cache) |

Each app is its own Flutter project with its own `pubspec.yaml`, routing table, and entry point — there is no shared `userType` toggle or combined login screen anymore. A person opens the **Customer App** to shop, a rider opens the dedicated **Rider App** to accept deliveries, and staff open the **Admin Panel** to manage everything. All three simply point at the same Firebase project, so data flows between them in real time via Firestore.

---

## Customer App — Features

**Authentication & Onboarding**
- Email/password sign-up and login via Firebase Authentication
- Mandatory email verification with an auto-polling "waiting for verification" screen (checks every 3 seconds) and a resend option
- Forgot-password flow (reset link sent to email)
- First-time **Setup Profile** step — display name plus a 25-option avatar picker
- Session restore on app relaunch via `SplashScreen`, rehydrating Hive from Firestore if the local profile is empty

**Home**
- Category rail parsed from an admin-managed icon-name convention (e.g. `Electronics-headphone`) and mapped to Iconsax/Material icons
- Auto-rotating promotional banner carousel
- One-time animated "free delivery / easy returns / secure payments" fly-down banner shown after onboarding
- Live product grid streamed straight from Firestore, filterable by category
- Cart and Wishlist badges update in real time

**Search & Discovery**
- Keyword search across product title and category
- Advanced filter sheet — category multi-select, price range, average rating range, and review-count range — with a "Clear filters" shortcut

**Product Detail**
- Multi-image gallery with page indicator and a pinch-to-zoom full-screen viewer
- Cloudinary-transformed thumbnails (auto width/height/format/quality) for fast loading
- Community 5-star rating system with live average recalculated transactionally on every submitted rating
- Add-to-cart / added-to-cart state, and a favourite/wishlist toggle

**Cart & Checkout**
- Hive-first cart with Firestore sync across devices
- Multi-step checkout: **Shipping → Payment**
- Address selection via a Google Maps picker (drag-to-pin), a Bangladesh-biased forward/reverse geocoding search, or one-tap "Current Location"
- Dynamic shipping options — Standard, Express, Next-Day, and a same-day **Home Delivery** option that only unlocks inside the serviceable area
- Card-details form with live number/expiry formatting and validation (demo payment UI — no real payment gateway wired in yet)
- Order summary with subtotal, shipping cost, and total, synced to both the customer's own order history and a shared `all_orders` collection the admin/rider side can act on

**Order Tracking**
- Order History list (Hive-first, Firestore fallback) with pull-to-refresh
- Order Detail screen with a live status timeline (Order Placed → Confirmed → Picked-up → In Transit → Out for Delivery → Delivered), auto-adjusting steps for home-delivery vs courier orders
- Real-time status log / activity feed with a "Load more" expander
- **Live Rider Tracking** screen (Google Maps + OSRM road-snapped routing) for home-delivery orders that are out for delivery, showing the rider's live position and an ETA-style route line

**Support Chat**
- One-on-one Firestore-backed support chat, per customer, with an initial auto-greeting
- Text and multi-image messages (images uploaded via Cloudinary), with a full-screen image viewer
- Customizable message-bubble color
- Unread badge on the bottom navigation bar, cleared automatically when the chat tab is opened

**Notifications**
- Firebase Cloud Messaging + OneSignal, wired up together — FCM for in-app foreground alerts, OneSignal for targeted server-side pushes (e.g. "your order is on the way")
- Local notification channel via `awesome_notifications` for delivery updates

**Profile**
- Edit display name & avatar
- Shortcuts to Favourites and Order History
- Sign-out confirmation sheet that clears in-memory state while keeping the local Hive cache for the next login

---

## Rider App — Features

A separate, lightweight Flutter app with **no local persistence at all** — every screen reads live from Firestore, so there's nothing to keep in sync on disk.

**Rider Login**
- Dedicated login screen — email/password only, no sign-up flow. Rider accounts are created exclusively by an admin through the Admin Panel's **Add Rider** flow, so a rider only ever needs to sign in with credentials already provided to them
- Blocked riders are rejected at login with a clear message, and immediately signed back out
- Forgot-password flow (reset link sent to email)
- Session restore on relaunch — the splash screen checks the current Firebase user and, if signed in, loads the rider's profile straight from `/riders/{uid}` in Firestore before landing on the home screen

**Location Confirmation**
- First-run and on-demand **location confirmation** — current-location-only for riders (no manual map dragging), used to determine which delivery zone they serve
- Confirmed location is written straight to the rider's Firestore document (`/riders/{uid}`) — there's no local cache of it

**Delivery Queue**
- Real-time stream of pending home-delivery orders, filtered to only those within a **5 km radius** of the rider's last confirmed location (Haversine distance calculation)
- One-tap **Claim Order**, implemented as a Firestore transaction so two riders can never claim the same order
- "Outside Dhaka" state - `home-delivery` availability is currently controlled via a single feature flag so the service area can be widened or narrowed without a client update

**Active Delivery**
- Active order card on the rider home screen linking into a full delivery detail view
- **Out for Delivery** flow gated behind a mandatory current-location confirmation, so the customer's live tracking map always starts from an accurate point
- Continuous rider location broadcasting to Firestore while an order is out for delivery (auto-stops once delivered)
- **Mark Delivered** action — pushes a delivery confirmation to the customer and appends a status log entry (in Bengali, matching the customer-facing timeline)
- Delivered-history list, streamed and sorted by delivery time

---

## Admin Panel — Features

A responsive GetX-powered dashboard (Firestore-only, no local persistence) with a collapsible sidebar shell that adapts between a permanent rail (≥800px) and a slide-out drawer on narrower screens.

**Authentication & Access Control**
- Email/password sign-up and sign-in, completely separate from customer/rider accounts
- Mandatory email verification with an auto-polling screen, matching the same UX pattern used on the customer/rider side
- Admin access is gated by an **email whitelist enforced in Firestore Security Rules** (`isAdmin()`), not just client-side logic — after verification, the app performs a read against a locked-down `admin_only_check` document; if it fails, the account is treated as unauthorized and signed out automatically with a "You are not verified to be Admin" notice
- Password-strength meter (4-bar indicator) on the sign-up form
- Forgot-password flow with reset-link email

**Dashboard**
- Responsive card grid (1–3 columns depending on width) summarizing: Total Sales, Total Orders, Total Products, Total Customers, Riders, Pending Orders, and Delivered Orders — most cards are tappable shortcuts into the relevant section
- **Top 3 Customers** and **Top 3 Riders** leaderboards (by revenue / delivered-order count), each with a dedicated full-list screen showing customer/rider name, email, and totals

**Products**
- Full product table (image, ID, title, category, price, rating) with search across ID/title/category
- Advanced filter dialog: category multi-select, price range, rating range, review-count range, and a numeric product-ID range, plus multi-key sorting
- Add/Edit Product form:
  - Manually assigned, unique **5-digit numeric ID** with debounced live availability checking against Firestore
  - Multi-image upload via Cloudinary, with automatic **transparent-background detection** (samples pixel alpha values on PNG uploads) to decide whether the storefront should render the image with `BoxFit.contain` (cutout-style product shots) or `BoxFit.cover`
  - Inline "create new category" shortcut without leaving the form
- Delete with confirmation dialog

**Categories**
- Table view showing product count, average rating, and total combined price per category, derived live from the products stream
- Add / Edit / Delete categories, stored as a single `Name-icon` string (e.g. `Electronics-headphone`) so the icon and display name travel together
- Renaming a category cascades: an batched Firestore write updates every affected product's `category` field in the same operation
- Search plus sort/range filtering (product count, average rating, total price) via the same filter-dialog pattern used on the Products screen

**Messages (Support Chat)**
- Inbox of all customer conversations, sorted by most recent activity, with a live unread-count badge in the sidebar
- Search conversations by customer name or email
- Split view on wide screens (conversation list + chat panel side-by-side) or full-screen navigation on narrow screens
- Text replies and multi-image replies (uploaded via Cloudinary) with a full-screen swipeable image viewer
- Opening a conversation automatically clears its unread counter

**Order History**
- Filter chips for every stage — All / Pending / Confirmed / Picked-up / In Transit / Available for Delivery / Out for Delivery / Delivered — with a live pending-count badge
- Search by Order ID
- Per-order **status progression controls**: sequential Confirm → Picked-up → In Transit buttons for every order, followed either by a "Mark Delivered" action (courier orders) or an "Available For Delivery" trigger that publishes the order into the rider-facing `delivery_orders` queue (home-delivery orders), with read-only Out for Delivery / Delivered indicators reflecting live rider status
- Order detail dialog: itemized list, delivery address, shipping method, and payment summary, with a one-tap copy of the short order ID

**Analytics**
- Sales trend charts (fl_chart line charts) for **Daily** (14-day), **Weekly** (8-week), and **Monthly** (6-month) revenue, each with the latest period's total highlighted
- **Most Ordered Products** table (by quantity, including pending orders)
- **Top Revenue Products** table (by completed-order revenue)
- **Highest Rated Products** table (rating between 3.0–5.0)
- **Best Selling Categories** — top 5 categories by total quantity sold, each showing its single best-selling product inline

**Riders**
- Rider directory with avatar, name, email, and a live "Blocked" indicator; search by name or email
- **Block / Unblock** a rider (with a confirmation dialog) — blocking does not delete the rider's account or delivery history, it only prevents further logins
- Per-rider **Delivered History** panel with a live total-delivered count, order-ID search, and a details dialog per order (same itemized breakdown as Order History)
- **Add Rider** flow, reachable from the login screen without an existing admin session:
  1. Admin fills in the new rider's email/password
  2. The account is created through a **secondary, isolated Firebase App instance** (`SecondaryAuthService`) so the currently signed-in admin is never signed out mid-flow
  3. The new rider verifies their email (auto-polling screen, resend option)
  4. Rider profile setup — name + optional avatar upload — writes to `riders/{uid}`. This is the **only** place a rider's profile gets created; the Rider App itself has no sign-up or profile-setup screen
  5. The secondary Firebase app instance is disposed and the admin is returned to the login screen with a success confirmation

---

## Screenshots

### Customer App

#### Auth
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/1 customer app/1 auth/0.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/1 auth/1.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/1 auth/2.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/1 customer app/1 auth/3.jpg" width="220"/></td>
  </tr>
</table>

#### Home & Product Categories
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/1 customer app/2 home/1.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/2 home/2.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/2 home/3.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/1 customer app/2 home/4.jpg" width="220"/></td>
  </tr>
</table>

#### Favourites and Search
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/1 customer app/3 favourites and search/1.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/3 favourites and search/2.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/3 favourites and search/3.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/1 customer app/3 favourites and search/4.jpg" width="220"/></td>
  </tr>
</table>

#### Product Detail Screen
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/1 customer app/4 product detail screen/1.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/4 product detail screen/2.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/4 product detail screen/3.jpg" width="220"/></td>
  </tr>
</table>

#### Cart and Checkout
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/1 customer app/5 cart and checkout/1.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/5 cart and checkout/2.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/5 cart and checkout/3.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/1 customer app/5 cart and checkout/4.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/5 cart and checkout/5.jpg" width="220"/></td>
  </tr>
</table>

#### Order Tracking and Notifications
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/1 customer app/6 order tracking and notifications/1.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/6 order tracking and notifications/2.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/6 order tracking and notifications/3.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/1 customer app/6 order tracking and notifications/4.jpg" width="220"/></td>
  </tr>
</table>

#### Rider Tracking and Notifications
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/1 customer app/7 rider tracking and notifications/1.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/7 rider tracking and notifications/2.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/7 rider tracking and notifications/3.jpg" width="220"/></td>
  </tr>
</table>

#### Order History with Order Details
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/1 customer app/8 order history with order details/1.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/8 order history with order details/2.jpg" width="220"/></td>
  </tr>
</table>

#### Profile
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/1 customer app/9 profile/1.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/9 profile/2.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/1 customer app/9 profile/3.jpg" width="220"/></td>
  </tr>
</table>

---

### Rider App
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/2 rider app/0.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/2 rider app/1.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/2 rider app/2.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/2 rider app/3.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/2 rider app/4.jpg" width="220"/></td>
    <td align="center"><img src="screenshots of all apps/2 rider app/5.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/2 rider app/6.jpg" width="220"/></td>
  </tr>
</table>

---

### Admin Panel Web App (Responsive)

#### Admin Auth
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/0 admin auth/1.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/0 admin auth/2.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/0 admin auth/3.png" width="700"/></td>
  </tr>
</table>

#### Dashboard
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/1 dashboard/1.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/1 dashboard/2.png" width="700"/></td>
  </tr>
</table>

#### Search Product (Product Management)
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/2 search product (product management)/1.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/2 search product (product management)/2.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/2 search product (product management)/3.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/2 search product (product management)/4.png" width="700"/></td>
  </tr>
</table>

#### Create and Update Product (Product Management)
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/3 create and update product (product management)/1.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/3 create and update product (product management)/2.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/3 create and update product (product management)/3.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/3 create and update product (product management)/4.png" width="700"/></td>
  </tr>
</table>

#### Categories Management
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/4 categories management/1.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/4 categories management/2.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/4 categories management/3.png" width="700"/></td>
  </tr>
</table>

#### Order Management
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/5 order management/1.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/5 order management/2.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/5 order management/3.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/5 order management/4.png" width="700"/></td>
  </tr>
</table>

#### Support Chat
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/6 support chat/1.png" width="700"/></td>
  </tr>
</table>

#### Analytics
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/7 analytics/1.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/7 analytics/2.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/7 analytics/3.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/7 analytics/4.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/7 analytics/5.png" width="700"/></td>
  </tr>
</table>

#### Rider Management
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/8 rider management/1.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/8 rider management/2.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/8 rider management/3.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/8 rider management/4.png" width="700"/></td>
  </tr>
</table>

#### Responsive
<table>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/9 responsive/1.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/9 responsive/2.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/9 responsive/3.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/9 responsive/4.png" width="700"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots of all apps/3 admin panel web app/9 responsive/5.png" width="700"/></td>
  </tr>
</table>

---

## Tech Stack

| Layer | Customer App | Rider App | Admin Panel |
|---|---|---|---|
| Framework | Flutter (Dart) | Flutter (Dart) | Flutter (Dart) |
| State Management | GetX (`GetxController`, reactive `.obs`, `Get.put`/`Get.find`, `GetPage` routing) | GetX | GetX |
| Auth | Firebase Authentication | Firebase Authentication (login only — no sign-up screen; accounts are admin-created) | Firebase Authentication (+ secondary isolated `FirebaseApp` instance for Add Rider) |
| Database | Cloud Firestore | Cloud Firestore | Cloud Firestore |
| Local Storage | Hive (typed adapters for products, cart items, orders, profile) | — none (fully Firestore-driven; no Hive dependency at all) | — none |
| Image Storage | Cloudinary | — (not needed; riders don't upload images) | Cloudinary |
| Push Notifications | Firebase Cloud Messaging + OneSignal | Firebase Cloud Messaging + OneSignal | — |
| Local Notifications | `awesome_notifications` | — | — |
| Maps & Location | `google_maps_flutter`, `geolocator`, Google Geocoding API, OSRM (road-snapped routing) | `google_maps_flutter`, `geolocator` (current-location only, no map dragging) | — |
| Analytics Charts | — | — | `fl_chart` |
| Other | `image_picker`, `cached_network_image`, `flutter_rating_bar`, `uuid`, `http` | `uuid`, `http` | `image_picker`, `image` (alpha-channel inspection for PNG cutouts), `cached_network_image`, `http` |

---

## Architecture

Each app is its own Flutter project. All three share the same Firestore collections but do **not** share Dart code.

### Customer App

```
customer_lib/
├── app/
│   ├── bindings.dart              # Global GetX dependency injection (permanent controllers)
│   ├── routes.dart                # Named route table
│   └── theme.dart                 # AppColors + ThemeData
├── data/
│   ├── models/
│   │   ├── product_model.dart         # Hive-backed product model (multi-image gallery, fit rules)
│   │   ├── cart_item_model.dart       # Hive-backed cart item
│   │   ├── order_model.dart           # Hive-backed order + shipping/status enums
│   │   ├── delivery_order_model.dart  # Firestore-only rider-facing delivery order (read-only here)
│   │   └── address_model.dart
│   └── services/
│       ├── firebase_service.dart          # Auth, profile, orders, cart/favorites sync, delivery tracking reads
│       ├── firestore_product_service.dart # Product/category streams, transactional ratings
│       ├── hive_service.dart              # Per-user Hive boxes (cart/favorites/orders/profile)
│       ├── location_service.dart          # Geocoding, current-location, service-area check
│       ├── cloudinary_service.dart        # Image upload
│       └── notification_service.dart      # FCM + OneSignal + local notification channel
├── modules/
│   ├── auth/                      # Login, Signup (with email-verification polling), Setup Profile
│   ├── address/                   # Map-based address picker (search / drag pin / current location)
│   ├── bottom_nav/                # Animated bottom bar with unread chat badge
│   ├── cart/
│   ├── chat/                      # Firestore support chat + image messages
│   ├── checkout/                  # Shipping → Payment stepper
│   ├── favorites/
│   ├── home/                      # Feed, categories, banners, promo animation
│   ├── order_history/             # List + detail + live status timeline
│   ├── product/                   # Product detail, gallery, ratings
│   ├── profile/
│   ├── search/                    # Keyword + advanced filters
│   └── tracking/                  # Live rider-tracking map (Maps + OSRM)
├── widgets/
│   └── product_card.dart
└── main.dart                      # Firebase init, Hive adapters, notification init, GetMaterialApp
```

### Rider App

```
rider_lib/
├── app/
│   ├── bindings.dart              # Global GetX dependency injection (RiderProfileController, AuthController)
│   ├── routes.dart                # Named route table (splash → login → rider-home only)
│   └── theme.dart                 # AppColors + ThemeData
├── data/
│   ├── models/
│   │   ├── order_model.dart           # Plain Dart model (OrderItem + DeliveryStatus) — no Hive
│   │   ├── delivery_order_model.dart
│   │   └── address_model.dart
│   └── services/
│       ├── firebase_service.dart      # Login-only auth, rider profile, delivery-order queue, location broadcast
│       ├── location_service.dart      # Current-location fetch, service-area check
│       └── notification_service.dart  # FCM + OneSignal
├── modules/
│   ├── auth/                      # Login only — no sign-up, no setup-profile screen
│   ├── address/                   # Locked "confirm current location" flow (no free map dragging)
│   ├── profile/
│   │   └── rider_profile_controller.dart  # In-memory GetX controller replacing Hive; loads from /riders/{uid}
│   ├── rider/                     # Rider home, delivery queue, claim, active delivery, delivered history
│   └── splash/
└── main.dart                      # Firebase init, notification init, GetMaterialApp — no Hive.initFlutter()
```

> The Rider App intentionally has **no `hive_service.dart`, no Hive model adapters, and no `.g.dart` files** — every piece of state (profile, delivery queue, active order, location) is either held in a `GetxController`'s in-memory reactive state or streamed live from Firestore. Nothing is written to disk.

### Admin Panel

```
admin_lib/
├── app/
│   ├── app_colors.dart            # Shared color palette (teal primary, dark sidebar, accent colors)
│   └── app_theme.dart             # Global ThemeData (inputs, buttons, cards, app bar)
├── core/
│   └── utils/
│       └── cloudinary_image_utils.dart   # Injects w_/h_/c_fill/f_auto/q_auto into Cloudinary URLs
├── data/
│   ├── models/
│   │   ├── admin_order_model.dart     # Mirrors /all_orders documents
│   │   ├── admin_product_model.dart   # Mirrors /products documents, incl. imagesPng fit flags
│   │   ├── chat_summary_model.dart    # /support_chat conversation summary
│   │   ├── rider_info_model.dart      # /riders document
│   │   └── rider_status.dart          # Rider delivery-status string constants
│   └── services/
│       ├── firestore_service.dart         # All Firestore reads/writes for the admin panel
│       ├── cloudinary_service.dart        # Image upload (shared upload preset with customer app)
│       ├── cloudinary_config.dart         # Cloud name + unsigned upload preset
│       └── secondary_auth_service.dart    # Isolated secondary FirebaseApp for Add Rider flow
├── modules/
│   ├── auth/                      # Login, Signup, Verify Email, Admin whitelist check, AuthGate
│   ├── shell/                     # AdminShell — responsive sidebar navigation + unread badges
│   ├── dashboard/                 # Summary cards + top customers/riders aggregation
│   ├── top lists/                 # Top 3 Customers / Top 3 Riders full-list screens
│   ├── products/                  # Product table, filters, add/edit form (ID + image handling)
│   ├── categories/                # Category table, aggregation, add/edit/delete
│   ├── messages/                  # Support chat inbox + conversation panel
│   ├── order_history/             # Filterable order table + status progression controls
│   ├── analytics/                 # Revenue trend charts + product/category leaderboards
│   └── riders/                    # Rider directory, block/unblock, delivered history, Add Rider
└── main.dart                      # Firebase init + GetMaterialApp(home: AuthGate())
```

---

## Core Data Flows

**Auth & Session — Customer App**
```
App Launch
    └── Firebase current user check
            ├── No user / unverified   →  LoginScreen
            └── Verified
                    ├── Profile already set up  → Home
                    └── First login              → Setup Profile → Home
```

**Auth & Session — Rider App**
```
App Launch
    └── Firebase current user check
            ├── No user           →  LoginScreen (email/password sign-in only)
            └── Signed in
                    └── Load rider profile live from /riders/{uid}
                            └── RiderHome
                                    (no local Hive cache — every relaunch re-fetches from Firestore)

Note: there is no sign-up or setup-profile step inside the Rider App itself.
Rider accounts and profiles are created entirely by an admin via the
Admin Panel's Add Rider flow (see below). A blocked rider is rejected
and signed out right at the login step.
```

**Auth & Session (Admin Panel)**
```
App Launch
    └── AuthGate listens to Firebase Auth state
            ├── No user               → LoginView / SignupView
            ├── User, not verified    → VerifyEmailView (auto-polls every 3s)
            └── User, verified
                    └── AdminCheckingView
                            └── Attempts a read on /admin_only_check/verify
                                    ├── Allowed (email in whitelist) → AdminShell
                                    └── Denied (rules reject read)   → sign out + "Not Authorized"
```

**Order Placement → Fulfilment**
```
Customer completes Checkout (Customer App)
    └── Order saved to Hive + /users/{uid}/orders (customer's own history)
    └── Mirror written to /all_orders (admin/rider-facing, with statusHistory log)

Admin processes the order (Order History screen):
    └── Confirm → Picked-up → In Transit  (courier path, or shared prefix for home-delivery)

If shippingType == home_delivery:
    └── Admin taps "Available For Delivery"
            └── /all_orders/{orderId}.availableForDelivery = true
            └── /delivery_orders/{orderId} created with riderStatus = pending
    └── Nearby riders (Rider App) see it in their live queue (≤ 5km, Firestore transaction to claim)
    └── Rider confirms location → marks Out for Delivery → live location streams to the Customer App's tracking screen
    └── Rider marks Delivered → customer + all_orders status updated, push notification sent
            └── Reflected instantly on the Admin's Order History and Riders → Delivered History

Else (courier path):
    └── Admin marks the order Delivered directly from Order History
```

**Support Chat**
```
Customer opens Chat tab (Customer App)
    └── Auto-greeting message created if the thread is empty
    └── Text / image messages written to /support_chat/{uid}/messages
    └── unreadForUser / unreadForAdmin counters drive nav-bar & admin badges

Admin opens Messages tab
    └── Selecting a conversation resets unreadForAdmin to 0
    └── Replies (text or Cloudinary images) increment unreadForUser
```

**Add Rider (Admin Panel → Rider App)**
```
Admin (from Login screen, no session required) → Add Rider form
    └── Account created via a secondary, isolated FirebaseApp instance
            (keeps the admin's own session untouched)
    └── New rider verifies email (admin polls every 3s for status)
    └── Admin fills in rider profile — name + optional Cloudinary avatar
            └── Writes /riders/{newUid}
    └── Secondary FirebaseApp instance signed out & disposed
    └── Admin returned to Login screen with a success snackbar

    The new rider can now sign directly into the Rider App with the
    credentials the admin created — the profile they see there is
    read live from /riders/{newUid}, never set up by the rider themself.
```

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.x
- A Firebase project with **Authentication** (Email/Password) and **Cloud Firestore** enabled
- A [Cloudinary](https://cloudinary.com) account with an **unsigned upload preset** (Customer App + Admin Panel)
- A [OneSignal](https://onesignal.com) app configured for push notifications (Customer App + Rider App)
- A Google Cloud project with **Maps SDK** and **Geocoding API** enabled

### Setup

This repository contains **three separate Flutter projects** — Customer App, Rider App, and Admin Panel. Repeat the relevant steps for each.

1. **Clone the repository**
   ```bash
   git clone https://github.com/TanvirAhmedCSE/shopx-multi-role-e-commerce-app-admin-customer-rider.git
   cd shopx-multi-role-e-commerce-app-admin-customer-rider
   ```

2. **Install dependencies** — inside each app's own project directory
   ```bash
   flutter pub get
   ```

3. **Firebase setup**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable **Email/Password** authentication and **Cloud Firestore**
   - Download `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS) into the correct platform directories for **each** app (Customer App, Rider App, and Admin Panel all connect to the **same** Firebase project)
   - Run `flutterfire configure` inside each app's project directory to generate its own `firebase_options.dart`
   - Apply the [Firestore Security Rules](#firestore-security-rules) below (a single rules file governs all three apps), and update the admin email whitelist inside `isAdmin()` to your own admin account(s)

4. **Cloudinary setup** (Customer App + Admin Panel)
   - Note your Cloud Name and create an unsigned upload preset
   - Update `cloudName` / `uploadPreset` in `lib/data/services/cloudinary_config.dart` in both apps — both should point at the same Cloudinary account so images are visible across all three apps

5. **OneSignal setup** (Customer App + Rider App)
   - Create a OneSignal app and update the App ID / REST API key in each app's `lib/data/services/notification_service.dart`

6. **Google Maps & Geocoding** (Customer App + Rider App)
   - Enable the Maps SDK (Android/iOS) and Geocoding API on your Google Cloud project
   - Add your Android/iOS Maps API key to each app's platform config, and update the key used in `location_service.dart` (and the tracking screen, Customer App only)

7. **Create your first rider account**
   - Riders can't sign themselves up. Run the Admin Panel first, sign in as an admin, and use **Riders → Add Rider** to create the account the rider will log into on the Rider App.

8. **Run each app**
   ```bash
   flutter run
   ```

---

## Configuration Notes

- The Customer App, Rider App, and Admin Panel are **fully independent Flutter projects**. There is no shared `userType` field driving a combined login screen or shared codebase anymore — each app has its own login flow and its own route table.
- The Rider App does not depend on Hive (or any local database) at all — it was intentionally trimmed to be Firestore-only. If you fork it, there's no `hive_service.dart`, no Hive model adapters, and no `Hive.initFlutter()` call in `main.dart` to worry about.
- Rider accounts and rider profile data (name, avatar) are created and edited **only** through the Admin Panel's Add Rider flow, writing directly to `/riders/{uid}`. The Rider App has no sign-up or setup-profile screen — logging in simply reads that same document.
- Admin access is **not** determined by a `userType` field — it's controlled entirely by the email whitelist inside the `isAdmin()` function in Firestore Security Rules (see below). To add or remove an admin, edit that list and redeploy the rules.
- The **home-delivery service-area check** (`_testAllowAllBangladesh` in `location_service.dart`) currently allows the whole country for testing; flip it off to restore the original Dhaka-metro bounding-box restriction.
- Order rating and delivery-status writes go through Firestore transactions to stay consistent under concurrent updates (e.g. two customers rating the same product, or two riders claiming the same order).
- Product IDs in the Admin Panel are manually assigned, unique 5-digit strings — uniqueness is checked live against Firestore before a product can be saved.
- The Admin Panel's Add Rider flow relies on a **secondary Firebase App instance** so that creating a rider account never signs the currently logged-in admin out. Make sure your Firebase config supports multiple named app instances (this is the default behavior of the `firebase_core` plugin).

---

## Firestore Security Rules

All three apps (Customer, Rider, and Admin Panel) connect to a **single Firebase project**, so a single rules file governs all of them.

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAdmin() {
      return request.auth != null && request.auth.token.email in [
        'REPLACE_EMAIL',
        'REPLACE_EMAIL'
      ];
    }

    match /admin_only_check/{docId} {
      allow read: if isAdmin();
    }

    match /users/{userId}/{document=**} {
      allow read: if request.auth != null && (request.auth.uid == userId || isAdmin());
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /support_chat/{userId}/{document=**} {
      allow read, write: if request.auth != null &&
        (request.auth.uid == userId || isAdmin());
    }

    match /all_orders/{orderId} {
      allow read: if request.auth != null &&
        (resource.data.userId == request.auth.uid || isAdmin());
      allow create: if request.auth != null &&
        request.resource.data.userId == request.auth.uid;
      allow update: if isAdmin() ||
        (request.auth != null &&
          request.resource.data.diff(resource.data).affectedKeys().hasOnly(['statusHistory']));
    }

    match /delivery_orders/{orderId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }

    match /riders/{riderId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && (request.auth.uid == riderId || isAdmin());
    }

    match /products/{productId} {
      allow read: if request.auth != null;
      allow create, delete: if isAdmin();
      allow update: if isAdmin() ||
        (request.auth != null &&
          request.resource.data.diff(resource.data).affectedKeys().hasOnly(['rating', 'ratingCount']));

      match /ratings/{userId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
    }

    match /categories/{categoryId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }
  }
}
```

**How this maps to app behavior:**

| Collection | Rule summary |
|---|---|
| `admin_only_check` | Read-only probe document used solely by the Admin Panel's `AdminCheckingView` to confirm the signed-in email is on the admin whitelist. |
| `users/{userId}` | Any signed-in user can read/write only their own profile (Customer App); admins can read any profile (needed for customer name lookups across Dashboard, Messages, Order History). |
| `support_chat/{userId}` | Only the owning customer or an admin can read/write a given support thread. |
| `all_orders/{orderId}` | Customers can read/create their own orders and append to `statusHistory`; only admins can otherwise update order status fields. |
| `delivery_orders/{orderId}` | Open to any signed-in user (riders claiming jobs in the Rider App, admins publishing them, the Customer App's tracking screen reading rider status) — access is intentionally broad here since it holds no sensitive PII beyond what's needed for delivery. |
| `riders/{riderId}` | Any signed-in user can read the rider directory (Customer App tracking screen, Admin Panel); only the rider themself (Rider App) or an admin can write to a rider's own document (e.g. block/unblock, location updates). |
| `products/{productId}` | Publicly readable to any signed-in user; only admins can create/delete; customers may update **only** `rating`/`ratingCount` (the review flow), everything else admin-only. |
| `products/{id}/ratings/{userId}` | Each customer manages only their own individual rating record, used to prevent duplicate ratings and to power the transactional average. |
| `categories/{categoryId}` | Publicly readable; write access restricted to admins. |

#### Remember to replace the two whitelisted emails inside `isAdmin()` with your own admin account(s) before deploying to a live Firebase project.

---

## Security Notes

- Firebase credentials (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`) are **not included** in this repository — configure your own Firebase project (and run `flutterfire configure` separately) for each of the three apps before running.
- The Cloudinary, OneSignal, and Google Maps/Geocoding keys referenced in the codebase are placeholders and must be replaced with your own.
- The OneSignal REST API key and the Google Geocoding API key are currently called directly from the client for simplicity. For production, move these behind a backend/Cloud Function so no secret key ships inside the app binary.
- No real payment gateway is integrated — the checkout's card form is a UI-only placeholder and does not process real transactions.
- Admin authorization is enforced server-side via Firestore Security Rules (see above), not just client-side checks — a rejected `admin_only_check` read forces an automatic sign-out, so a non-whitelisted account cannot reach the Admin Panel even if it bypasses the client UI.
- The Admin Panel's Add Rider flow uses a secondary, isolated `FirebaseApp` instance purely to avoid disrupting the admin's own session — it does not grant the new rider account any elevated privileges; a rider account is still bound by the same `riders/{riderId}` rules as any other rider document.
- Because the Rider App has no local persistence, signing out (or losing the Firebase session) leaves nothing cached on the device — every relaunch is a clean re-fetch from Firestore.

---

## License

This project is open-source and available under the [MIT License](LICENSE).

---

<div align="center">
Made with ❤️ and Flutter

*If you find this project useful, please give it a ⭐ on GitHub!*
</div>