# Arch Linux trademark / branding review and permission request

> Working notes + email draft for the ArchTitan OS public release.
> This is not legal advice. For a real product launch, have your university supervisor and an IP lawyer review it.

## 1. Short answer

Yes — there is a real trademark issue, and it gets **much bigger** if you add a paid subscription.

Arch Linux's official policy says:

- **Any mark beginning with the letters “ARCH” is sufficiently similar to an Arch trademark that permission is needed.** `ArchTitan` starts with `Arch`, so the name itself needs permission even for a free student project.
- **Any commercial use requires explicit permission from the Arch Linux Project Lead.** A subscription plan is commercial use.
- **Combining an Arch mark with another word/logo** (their examples include things like “Club Arch Linux” / “ArchBooks”) is listed as very unlikely to be approved. Our logo is a modified blue Arch-style `A` combined with `TITAN`.
- The **™ symbol must stay intact** whenever their logos are displayed. The project README's `logo=arch-linux` badge does not show the ™ declaration.
- A substantially modified product may only say **“derived from Arch Linux” / “based on Arch Linux”** as a factual statement; it may **not use “Arch” as part of the product's brand** without a licence.

Given the amount of custom work in this repo (custom daemons, custom UI/design system, custom packages in `custom-repo/`, custom bootloader/plymouth/installer branding), Arch would probably classify ArchTitan as a substantially modified derivative, not a minimal “Remix”. Their policy says such products are **unlikely to be approved** for trademark use.

## 2. Exactly where our project uses Arch branding

| Location | Use | Risk |
| :--- | :--- | :--- |
| Project name | `ArchTitan OS`, `ArchTitan`, `ArchTitan OS Linux` | High — starts with `ARCH`; combined mark |
| `README.md` line 3 | shields.io badge `Base-Arch Linux` with `logo=arch-linux` | Medium/High — uses Arch logo without ™; commercial site context |
| `README.md`, docs, wiki | Many factual references to “Arch Linux”, `archiso`, ArchWiki links | Low/Medium — factual references are allowed if clearly not endorsement |
| `assets/logo.png`, `wiki/assets/logo.png`, `airootfs/usr/share/pixmaps/archtitan-logo.png`, plymouth/grub/calamares logos | Blue stylised `A` closely resembling Arch's stylised logo, combined with `TITAN` wordmark, no ™ | High — altered/combined logo |
| `profiledef.sh` | `iso_publisher="ArchTitan OS"`, `iso_application="Arch Titan Linux Live Environment"` | Medium — “Arch Titan Linux” can read as an official Arch product |
| `pacman.conf` + `custom-repo/` | Extra non-official packages (`bibata-archtitan`, custom calamares builds, etc.) | High for “Remix” argument — policy calls out non-Arch-repo packages as making approval unlikely |
| Planned subscription | Monetised distribution/updates/product | High — commercial use is explicitly restricted |

## 3. Two realistic routes

### Route A — safest for the FYP deadline (recommended)

1. Rebrand before public release: drop `Arch` from the product name and logo, e.g. **Titan OS / Titan Linux / TitanDesk** (check name availability first).
2. Replace the Arch-style `A` logo with a genuinely original Titan mark.
3. Keep only factual wording: “Titan OS is an independent project based on Arch Linux. Not affiliated with or endorsed by Arch Linux.”
4. Remove the Arch logo badge from the README, or replace it with plain text “Based on Arch Linux”.
5. Keep ArchLinux.org / ArchWiki links as ordinary reference links, not as endorsement.
6. For the “Linux” in a product name, apply for the free Linux Foundation sublicense (details below).

This route does **not** need Arch permission for the new brand, and it avoids delaying your FYP release.

### Route B — ask permission to keep `ArchTitan` and the logo

You can send the email below, but **apply before publishing**, and be prepared for a “no”. Do not launch first and ask later. Arch likely will not approve a combined `ArchTitan` brand, especially with commercial plans.

## 4. Email to Arch Linux (send to `trademarks@archlinux.org`)

**Subject:** Trademark permission request — ArchTitan OS (student FYP project, possible future subscription)

```text

## 5. Separate note: the Linux® mark

If you keep `Linux` in a commercial product/brand name such as `ArchTitan OS Linux`, the Linux Foundation says a **free, perpetual sublicense** is required when “Linux” is part of a trademark/brand identifier for software goods or services — even if the mark is unregistered and even if you make no money. Apply at:

- https://www.linuxfoundation.org/legal/request-a-sublicense
- Contact: `trademarks@linuxfoundation.org`

Until then, use plain factual wording with attribution, e.g.:

> ArchTitan OS is a Linux®-based distribution. Linux® is the registered trademark of Linus Torvalds in the U.S. and other countries.

For a commercial brand, also add:

> The registered trademark Linux® is used pursuant to a sublicense from the Linux Foundation, the exclusive licensee of Linus Torvalds, owner of the mark on a world-wide basis.

## 6. About ArchCraft as a precedent

Short version: **do not treat ArchCraft as proof that permission is available.**

- ArchCraft's name begins with `Arch`, which the Arch policy says needs permission.
- ArchWiki's *Talk:Arch-based distributions* page currently lists **Archcraft** under:
  > “Following projects are excluded since they were found to misuse the Arch Linux trademark”
  
  Source: https://wiki.archlinux.org/title/Talk:Arch-based_distributions#Excluded_projects
- On the same page, a maintainer reported that for another Arch-named project, they asked the Arch Project Lead (`Anthraxx`) directly whether it had authorisation and were told **no**. That shows the wiki's exclusion list is connected to actual authorisation checks, not just personal opinion.
- ArchCraft also sells “Premium” themes/configs/ISOs (https://archcraft.io/premium.html), i.e. commercial activity, which is the category Arch's policy treats most strictly.
- I found **no public statement from Arch Linux granting ArchCraft a trademark licence**. It is possible a private arrangement exists, but an unpublicised one cannot be relied on by us, and any licence would be specific to that project and revocable.

So yes — we can and should email `trademarks@archlinux.org`, exactly as in section 4. But ArchCraft is an example of why we should **not** launch first and assume tolerance.

## 7. Pre-send checklist

- [ ] Fill in every `[placeholder]` in the email.
- [ ] Attach the actual logo files and screenshots; do not expect them to inspect the repo.
- [ ] Decide internally: are you willing to rebrand to `Titan OS` if Arch says no? (Recommended answer: yes.)
- [ ] Do not publish the ISO/README publicly until either permission arrives or rebranding is done.
- [ ] Keep a copy of any reply as proof of permission or evidence of the request.
- [ ] Check other third-party marks in the design (e.g. “One UI” wording, fonts, icon themes) separately.
