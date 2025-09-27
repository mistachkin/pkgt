# Package Client Toolset (pkgt)

> Secure, cross‑platform package delivery for **Tcl** and **Eagle** — designed to fetch on‑demand or pre‑install packages with cryptographic verification. ([GitHub][1])

[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](LICENSE)

---

## Table of contents

* [Why pkgt?](#why-pkgt)
* [What’s in this repo](#whats-in-this-repo)
* [Security model at a glance](#security-model-at-a-glance)
* [Supported runtimes & prerequisites](#supported-runtimes--prerequisites)
* [Quick start (consumers)](#quick-start-consumers)

  * [Tcl](#tcl-consumers)
  * [Eagle](#eagle-consumers)
* [Quick start (package producers & maintainers)](#quick-start-package-producers--maintainers)

  * [Authoring a package](#authoring-a-package)
  * [Signing your artifacts](#signing-your-artifacts)
  * [Uploading / publishing](#uploading--publishing)
* [How it works (architecture)](#how-it-works-architecture)
* [Configuration](#configuration)
* [FAQ](#faq)
* [Contributing](#contributing)
* [License](#license)

---

## Why pkgt?

Distributing Tcl/Eagle packages has traditionally involved a mix of ad‑hoc steps, platform quirks, and trust problems. **pkgt** addresses this by:

* **Fetching on demand** (transparent to `package require`) or **pre‑installing** ahead of time. ([Tcl][2])
* **Verifying everything**: package metadata and files are **OpenPGP** signed; **Eagle** scripts are **also** signed with **Harpy**. ([Tcl][2])
* **Working for both Tcl and Eagle** with the same client toolset. ([GitHub][1])

---

## What’s in this repo

```
.
├─ client/1.0/neutral/
│  ├─ VERSION               # current toolset version (e.g., 1.0.10)
│  ├─ common.tcl            # shared Tcl helpers
│  ├─ pkgIndex.tcl          # Tcl-side integration
│  ├─ pkgIndex.eagle        # Eagle-side integration (Harpy-signed variants included)
│  ├─ pkgd.eagle            # package downloader library (client side)
│  ├─ pkgr.eagle            # package repository client library
│  ├─ pkgu.eagle            # package uploads client library
│  ├─ pkgr_setup.eagle      # setup/configure repositories & keys
│  ├─ pkgr_install.eagle    # install/persist packages locally
│  └─ pkgr_upload.eagle     # upload/publish packages (maintainers)
├─ externals/
│  ├─ Eagle/lib/Eagle1.0/   # Eagle library packaged for Tcl
│  └─ Harpy/Tools/sign.eagle# Harpy code-sign tooling
├─ tools/
│  ├─ deploy.bat
│  ├─ pkgr_an_d_get.sh
│  └─ pkgr_an_d_install.sh  # helper scripts to fetch/install the client
└─ doc/
   └─ v1.html               # v1 toolset documentation (reference)
```

> File names and layout above come from the initial import. See the commit tree for the authoritative list. The current version is **1.0.10**. ([GitHub][3])

---

## Security model at a glance

* **Metadata path**: The client asks a repository service for a package that satisfies a **TIP #268** version requirement. The server returns a small **signed script** that knows what to fetch. ([Tcl][2])
* **File path**: The client downloads one or more **OpenPGP‑signed** files and verifies them **before** the package is made available to the interpreter. ([Tcl][2])
* **Eagle scripts**: In addition to OpenPGP, **Harpy** signatures are verified for Eagle files. ([Tcl][2])

**Result:** You get transparent, on‑demand package resolution with end‑to‑end verification — suitable for both public and private repositories. ([Tcl][2])

---

## Supported runtimes & prerequisites

* **Tcl**: Standard Tcl (8.5+) environments.
* **Eagle**: Any environment that can run Eagle scripts.
* **Platforms**: Windows, Linux, macOS (no OS‑specific assumptions in the client libraries).
* **Tools inside this repo**:

  * **Tcl integration** via `client/1.0/neutral/pkgIndex.tcl` and `client/1.0/neutral/common.tcl`. ([GitHub][3])
  * **Eagle integration** via `client/1.0/neutral/pkgIndex.eagle` (+ Harpy-signed variants). ([GitHub][3])
  * **Harpy signing utility** at `externals/Harpy/Tools/sign.eagle`. ([GitHub][3])
  * **Eagle library packaged for Tcl** under `externals/Eagle/lib/Eagle1.0/`. ([GitHub][3])

> You don’t need to install external “gpg” binaries to *use* pkgt; signature verification is handled by the client toolset and its libraries. See `doc/v1.html` for the full reference. ([GitHub][4])

---

## Quick start (consumers)

### Tcl (consumers)

1. **Vendor the client** (recommended layout):

   ```
   your-project/
     vendor/pkgt/           # this repo (or a release snapshot)
       client/1.0/neutral/  # Tcl/Eagle indices + client libs
       externals/           # Eagle + Harpy helpers
   ```

2. **Add pkgt to Tcl’s search path** (e.g., early in your app bootstrap):

   ```tcl
   # Point this to where you vendored pkgt
   set pkgtRoot [file normalize [file join [pwd] vendor pkgt]]

   # Add pkgt client + externals to Tcl's auto_path:
   lappend ::auto_path [file join $pkgtRoot client 1.0 neutral]
   lappend ::auto_path [file join $pkgtRoot externals Eagle lib Eagle1.0]
   ```

3. **Configure repositories / keys**
   The easiest path is to use the **Eagle setup script** (ships with the client):

   ```tcl
   # From Tcl, invoke Eagle to run the setup, or run it once offline with an
   # Eagle interpreter (see the Eagle quick start below).
   # After setup, your configuration will be persisted for subsequent runs.
   ```

4. **Use packages normally**
   With the indices on your path, `package require <name> ?version?` will be
   satisfied locally **or** resolved via pkgt’s secure repository client (on demand). ([Tcl][2])

> Tip: If you prefer to **pre‑install** packages into an application image or cache, run the `pkgr_install.eagle` helper once and ship the resulting package tree with your app. ([GitHub][3])

---

### Eagle (consumers)

1. **Vendor the client** as above.

2. **Add pkgt to the Eagle package path**, then run setup:

   ```tcl
   # Inside Eagle
   set pkgtRoot [file normalize "./vendor/pkgt"]
   path add [file join $pkgtRoot client 1.0 neutral]

   # Optional: also add externals if not on your path already
   path add [file join $pkgtRoot externals Eagle lib Eagle1.0]

   # Run interactive/CLI setup to register repository endpoints and API keys:
   source [file join $pkgtRoot client 1.0 neutral pkgr_setup.eagle]
   ```

3. **Pre‑install (optional)**:

   ```tcl
   # Still in Eagle
   source [file join $pkgtRoot client 1.0 neutral pkgr_install.eagle]
   # Follow prompts or pass arguments to install and persist selected packages.
   ```

4. **Use packages**:

   ```tcl
   # Resolve on-demand (transparent)
   package require MyPkg 1.2
   ```

All of the above entry points (`pkgr_setup.eagle`, `pkgr_install.eagle`) are part of the client `client/1.0/neutral` directory. ([GitHub][3])

---

## Quick start (package producers & maintainers)

### Authoring a package

1. **Write your package** the normal Tcl/Eagle way:

   * Provide a `pkgIndex.tcl` and/or `pkgIndex.eagle` that does `package provide <name> <version>`.
   * Organize your files under a single directory named after your package.

2. **Test locally**: ensure `package require <name> <version>` works from a clean interpreter when your package directory is on `auto_path` (Tcl) or `path` (Eagle).

3. **Decide distribution mode**:

   * **On‑demand**: pkgt can fetch files individually as directed by repository metadata.
   * **Pre‑installable**: you can ship the package directory as a ready‑to‑use tree.

> The pkgt repository server resolves a TIP #268 version constraint, returns a small signed script, and instructs the downloader which files to fetch. All files are OpenPGP‑signed; Eagle files are also Harpy‑signed. ([Tcl][2])

### Signing your artifacts

* **Harpy (Eagle)**: use the included Harpy tool to sign Eagle scripts:

  ```tcl
  # Eagle
  source [file join $pkgtRoot externals Harpy Tools sign.eagle]
  # See 'sign.eagle' usage for signing options.
  ```

  (Tool location: `externals/Harpy/Tools/sign.eagle`.) ([GitHub][3])

* **OpenPGP (all files)**: ensure each distributed file has an OpenPGP signature the client can verify. (The client will refuse unsigned or invalidly signed files.) ([Tcl][2])

### Uploading / publishing

Use the **uploads** client and/or helper:

```tcl
# Eagle
set pkgtRoot [file normalize "./vendor/pkgt"]
path add [file join $pkgtRoot client 1.0 neutral]

# Upload tool:
source [file join $pkgtRoot client 1.0 neutral pkgr_upload.eagle]
```

> The repository (metadata) server is managed via a web UI; the file server typically runs on **Fossil** and uses repository users/keys for access. Public and private publishing models are supported. ([Tcl][2])

---

## How it works (architecture)

* **Repository Client (`pkgr.eagle`)**
  Locates packages meeting a TIP #268 constraint by talking to the repository service, receives a **signed** resolver script, verifies it, and evaluates it (in Tcl or Eagle as appropriate). ([Tcl][2])

* **Downloader (`pkgd.eagle`)**
  Fetches one or more **OpenPGP‑signed** files, verifies signatures, and exposes the package to the interpreter. Optionally persists installed packages to a local cache or application image. ([Tcl][2])

* **Uploads Client (`pkgu.eagle`)**
  Assists maintainers in pushing new versions to the repository/file server. ([GitHub][3])

* **Language integration**
  `pkgIndex.tcl` and `pkgIndex.eagle` provide seamless integration so ordinary `package require` requests trigger the above flow if the package isn’t present locally. Harpy‑signed index variants are provided for Eagle. ([GitHub][3])

A short slide deck from Tcl’16 gives a good overview of this flow and security model. ([Tcl][2])

---

## Configuration

* **Run once**: `pkgr_setup.eagle` to register:

  * One or more **repository endpoints** (metadata server URLs).
  * **File server** base URLs.
  * API keys (**read** and **full**) for private/personal repositories.

* **Persisted settings**: setup writes settings that subsequent runs of the client will use automatically (both for on‑demand resolution and pre‑installation). See `doc/v1.html` for parameter names and advanced options. ([GitHub][3])

---

## FAQ

**Q. Does this replace `pkgIndex.tcl`?**
A. No. pkgt **uses** normal package metadata; it just enables secure **remote** resolution and delivery when a required package is not available locally. ([Tcl][2])

**Q. How are Eagle scripts treated differently?**
A. They carry **two** signatures: OpenPGP (like all files) and **Harpy** (Eagle‑specific). Both must validate before the package is exposed to the interpreter. ([Tcl][2])

**Q. Can I keep some packages private?**
A. Yes. Repository access uses API keys; file serving can be on a private Fossil instance. Public/private mixes are supported. ([Tcl][2])

**Q. What version of the pkgt client is this?**
A. See `client/1.0/neutral/VERSION` (currently **1.0.10**). ([GitHub][3])

---

## Contributing

* Open issues and PRs are welcome.
* Please test on both **Tcl** and **Eagle** when touching shared client code (`client/1.0/neutral/`).
* Keep security guarantees intact: never merge changes that weaken signature checks or disable verification by default. (Harpy and OpenPGP verification are core to pkgt.) ([Tcl][2])

---

## License

This project is available under the **BSD 3‑Clause** license. See [LICENSE](./LICENSE). ([GitHub][1])

---

### References & further reading

* **Repo overview & purpose**: *“securely obtain and use packages for both Tcl and Eagle”* — GitHub repo description. ([GitHub][1])
* **Initial import & file layout** (client libraries, indices, tools, externals, docs). ([GitHub][3])
* **Version file** (`client/1.0/neutral/VERSION`: 1.0.10). ([GitHub][3])
* **Security & architecture slides** (Tcl’16 talk: Package Repository Client & Server). ([Tcl][2])

---

> *Maintainers:* if you’d like, I can also add a minimal **Makefile** (or simple `tclsh`/`Eagle` scripts) to automate `setup → install → smoke-test` locally using the helper entry points above.
