<h1 align="center" style="border-bottom: none">
  <div>
    <a href="https://www.docuseal.com">
      <img  alt="DocuSeal" src="https://github.com/docusealco/docuseal/assets/5418788/c12cd051-81cd-4402-bc3a-92f2cfdc1b06" width="80" />
      <br>
    </a>
    DocuSeal Plus
  </div>
</h1>
<h3 align="center">
  Open source document filling and signing - Plus Edition
</h3>
<p align="center">
  <strong>Forked and enhanced by <a href="https://www.speedbits.io">Speedbits</a> / Smart In Venture GmbH for <a href="https://speedbits.io/infinity-tools/">Infinity Tools</a></strong>
</p>
<p>With <a href="https://speedbits.io/infinity-tools/">Infinity Tools</a>, installation of DocuSeal with Plus features is super easy - included in the Pro version (pay-once-use-forever)!

---

> **⚠️ Important Notice**
>
> This is a **forked version** of the official [DocuSeal](https://github.com/docusealco/docuseal) open-source project with additional "Plus Features" enabled. The Plus features were developed with the assistance of AI tools. **There may be errors, bugs, or security vulnerabilities.** Use at your own risk.
>
> **Speedbits (Smart In Venture GmbH) does not assume any liability** for damages arising from the use of this software.

---

## Plus Features (Added in this Fork)

This fork includes the following features that are normally part of DocuSeal Pro:

- **User Management** - Multiple user roles (Admin, Editor, Viewer) with granular permissions
- **Company Logo Personalization** - Upload and display your company logo on documents
- **Email Reminders** - Automatic email reminders for pending signature requests

## Original DocuSeal Features

- PDF form fields builder (WYSIWYG)
- 12 field types available (Signature, Date, File, Checkbox etc.)
- Multiple submitters per document
- Automated emails via SMTP
- Files storage on disk or AWS S3, Google Storage, Azure Cloud
- Automatic PDF eSignature
- PDF signature verification
- Mobile-optimized
- 7 UI languages with signing available in 14 languages
- API and Webhooks for integrations
- Easy to deploy in minutes

## Deploy

### Docker Images

DocuSeal Plus images are available from GitHub Container Registry for both **AMD64** and **ARM64** architectures:

```
ghcr.io/speedbitsinfinitytools/docuseal-plus:latest
ghcr.io/speedbitsinfinitytools/docuseal-plus:2.3.0
ghcr.io/speedbitsinfinitytools/docuseal-plus:2.3.0.1
```

#### Version Scheme

- `latest` - Always the most recent build
- `X.Y.Z` - Base DocuSeal version (e.g., `2.3.0`)
- `X.Y.Z.N` - Plus release number (e.g., `2.3.0.1`, `2.3.0.2`, ...)

The first three digits match the upstream DocuSeal version. The fourth digit is our Plus release counter.

#### Docker Run

```sh
docker run --name docuseal-plus -p 3000:3000 -v.:/data ghcr.io/speedbitsinfinitytools/docuseal-plus:latest
```

By default, the container uses SQLite. For PostgreSQL or MySQL, specify the `DATABASE_URL` environment variable.

#### Docker Compose

Download docker-compose.yml into your private server:
```sh
curl https://raw.githubusercontent.com/speedbitsinfinitytools/docuseal-plus/master/docker-compose.yml > docker-compose.yml
```

Run the app under a custom domain over HTTPS using Docker Compose (make sure your DNS points to the server to automatically issue SSL certs with Caddy):
```sh
sudo HOST=your-domain-name.com docker compose up
```

## Contributing

We are grateful for any help, contributions, bug reports, and code fixes!

If you find issues or have improvements to suggest, please:
- Open an issue on this repository
- Submit a pull request with your changes
- Share feedback with the community

## Original Project

This project is a fork of the official DocuSeal project:
- **Original Repository**: [github.com/docusealco/docuseal](https://github.com/docusealco/docuseal)
- **Original Website**: [docuseal.com](https://www.docuseal.com)
- **Original Demo**: [demo.docuseal.tech](https://demo.docuseal.tech)

For DocuSeal Pro features not included in this fork (SMS verification, SSO/SAML, conditional fields, bulk send, etc.), please consider supporting the original DocuSeal team at [docuseal.com/pricing](https://www.docuseal.com/pricing).

## License

Distributed under the **AGPLv3 License**. See [LICENSE](https://github.com/docusealco/docuseal/blob/master/LICENSE) for more information.

- Original DocuSeal © 2023 DocuSeal LLC
- Modifications in this fork © 2026 Smart In Venture GmbH

All modifications are subject to the AGPLv3 license terms. The source code for this fork is publicly available at [github.com/speedbitsinfinitytools/docuseal-plus](https://github.com/speedbitsinfinitytools/docuseal-plus).

## Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS, COPYRIGHT HOLDERS, OR SPEEDBITS (SMART IN VENTURE GMBH) BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

The Plus features in this fork were developed with AI assistance and have not undergone comprehensive security audits. For production use with sensitive documents, please evaluate the code carefully or consider the official DocuSeal Pro offering.
