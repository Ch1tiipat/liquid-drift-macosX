# Licensing and release decisions

## Decided
- **Alpha and beta are free, with no lock and no key.** A key system may come later when the owner decides to sell.
- The repo is public from the start (owner decision, so AI agents can fetch it). There is no LICENSE file yet,
  so all rights are reserved. Do not add code, images or other assets without checking their license and provenance.
- Code is written from scratch. Other apps (for example Droppy, NotchNook, Boring Notch) are used
  for ideas only. Droppy is reported to be published under GPL-3.0 with the Commons Clause (check its repo), so copying its code
  would bind this project to those terms.
- No Apple Developer Program membership for now. Builds are not notarized, so other people will
  see a Gatekeeper warning. Alpha users either build from source or follow written steps to allow the app.

## Not decided yet: the code license
Pick before the alpha release. Until then, all rights are reserved. Read the real license text, or ask a lawyer.

| Option | Idea | Note |
|---|---|---|
| MIT / Apache-2.0 | Anyone may use, change, sell | **Open source.** Cannot be taken back once released. Does not fit "pay later". |
| Source-available (for example PolyForm, Business Source License, Commons Clause) | Code is readable, use is limited | **Not open source.** Check what each one allows: some allow free personal use, which would also cover other people. |
| All rights reserved + visible code | Others may read only | Simple, but no reuse by anyone. |

**Important:** a license applies to the version you release it with. If alpha is released under a
permissive license, those copies stay under it forever, even if later versions change. If you plan to
sell later, choose a license for the alpha that already fits that plan.

Do not call the project "open source" in the README unless the license is OSI-approved.

## Logo provenance
- The main logo reference was made with an AI image tool.
- Record here before release: tool name and version, date, prompt, the original file, and the tool's
  commercial-use terms.
- Legal status of AI-made images differs by country. Not checked for Thailand. Review before the 1.0 release.
- Plan: redraw the drop as a vector by hand.

## Name
- Working name: **Liquid Drift**. A first web search found no macOS app with this name. This is not a
  trademark check. Before 1.0: check App Store, GitHub, domain names and trademark databases.

## Checklist before the alpha release (the repo is already public)
- [ ] `LICENSE` chosen and added
- [ ] `THIRD_PARTY_LICENSES.md` complete
- [ ] Logo provenance recorded
- [ ] Security checklist in `docs/SECURITY_MODEL.md` done
- [ ] README tells users how to run an un-notarized app (after checking the real steps on macOS 27)
- [ ] Full git history scanned for secrets

## Future license key (design note, not built)
Offline, signed with Ed25519. The app contains only the public key. The key file binds to a hashed
device ID and has an expiry date. No server. Revocation is not possible without a server, so use expiry.
Private key stays in the owner's Keychain, never in the repo, never in chat or agent prompts.
