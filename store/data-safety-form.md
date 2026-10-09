# Google Play — Data Safety Form answers

Copy these into Play Console → App content → Data safety.
They must agree with `privacy-policy.html` and the merged `AndroidManifest.xml`
permissions (INTERNET, ACCESS_FINE/COARSE_LOCATION, VIBRATE, WAKE_LOCK,
FOREGROUND_SERVICE, FOREGROUND_SERVICE_MEDIA_PLAYBACK).

## Section 1 — Data collection and security

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | **N/A** (no data collected) |
| Do you provide a way for users to request that their data be deleted? | **N/A** — all data is local; deleting the app removes it |

Because the answer to collection is **No**, every data-type section
(Location, Personal info, Financial info, Messages, Photos, Files, Audio,
Contacts, Calendar, App activity, Web browsing, App info & performance,
Device or other IDs) is answered **not collected / not shared**.

## Section 2 — Location (the one reviewers scrutinise)

Location is **processed on-device only** and never transmitted, so it is *not*
"collected" under Play's definition (collection = transmission off the device).

If the console forces a Location answer, use:

| Field | Answer |
|---|---|
| Approximate location | **Not collected** |
| Precise location | **Not collected** |
| Purpose (if asked) | App functionality — Qiblah direction and prayer times |
| Ephemeral processing | **Yes** — computed on-device, never stored on a server |

## Section 3 — Permissions justification (App content → Sensitive permissions)

| Permission | Justification text |
|---|---|
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Used only to compute the Qiblah bearing and local prayer times. The user may deny it and set their city manually; the rest of the app works fully without it. Location never leaves the device. |
| `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Plays Qur'an recitation in the background with a standard media notification. |
| `WAKE_LOCK` | Keeps the screen on during recitation (user-toggleable). |
| `VIBRATE` | Haptic feedback in the digital tasbih (user-toggleable). |
| `INTERNET` | Streams recitation audio from public Qur'an servers. |

## Section 4 — Other declarations

| Question | Answer |
|---|---|
| Ads | **No ads** |
| In-app purchases | **No** |
| Target audience | Everyone (all ages); not primarily child-directed |
| News app | No |
| COVID-19 contact tracing | No |
| Data safety contact | triadisetiawan19@gmail.com |
| Privacy policy URL | https://noor-quran-wheat.vercel.app/privacy-policy.html |

## Why the app qualifies as "no data collected"

- No account, no login, no analytics SDK, no ad SDK.
- Bookmarks, last-read, tasbih count and preferences live in local storage only.
- Location is read on-device for a calculation; the result is never sent anywhere.
- Audio is streamed from public servers; those servers see an IP address the same
  way any browser request would — that is not data the developer collects.
