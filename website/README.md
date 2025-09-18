# Aura One Landing Page

The official landing page for Aura One - an AI-powered automatic journaling app that preserves your memories locally with complete privacy.

## 🚀 Quick Start

```bash
# Using bun (recommended)
make install   # Install dependencies
make dev       # Start development server

# Or using bun directly
bun install
bun run dev
```

Visit `http://localhost:5173` to see the site.

## 📦 Available Commands

### Using Makefile (Recommended)
```bash
make help      # Show all available commands
make install   # Install dependencies with bun
make dev       # Start development server
make build     # Build for production
make preview   # Preview production build
make clean     # Clean build artifacts and node_modules
```

### Using bun directly
```bash
bun install            # Install dependencies
bun run dev            # Start dev server at http://localhost:5173
bun run build          # Build for production
bun run preview        # Preview production build
```

## 🎨 Features

- **🌗 Dark/Light Mode**: Automatic system preference detection with manual toggle
- **📱 Fully Responsive**: Works perfectly on all devices from mobile to desktop
- **✨ Smooth Animations**: Framer Motion powered animations and parallax effects
- **🎨 Consistent Theme**: Exact color scheme from the mobile app
- **⚡ Lightning Fast**: Static site built with Vite for optimal performance
- **🔍 SEO Optimized**: Meta tags and Open Graph configured

## 🛠 Tech Stack

- **React 18** - UI framework
- **Vite** - Build tool and dev server
- **TailwindCSS** - Utility-first CSS framework
- **Framer Motion** - Animation library
- **Lucide React** - Icon library
- **Bun** - JavaScript runtime and package manager

## 📂 Project Structure

```
website/
├── src/
│   ├── components/         # React components
│   │   ├── Navigation.jsx  # Header with dark mode toggle
│   │   ├── Hero.jsx        # Landing hero section
│   │   ├── Features.jsx    # Feature cards grid
│   │   ├── Screenshots.jsx # App screenshots carousel
│   │   ├── Privacy.jsx     # Privacy-first section
│   │   ├── OpenSource.jsx  # Open source information
│   │   ├── CTA.jsx        # Call-to-action section
│   │   └── Footer.jsx     # Footer with links
│   ├── App.jsx            # Main app component
│   └── index.css          # Tailwind styles
├── public/
│   └── logo.svg          # Aura One logo
├── dist/                 # Production build (generated)
├── Makefile             # Build commands
├── tailwind.config.js   # Tailwind configuration
├── vite.config.js      # Vite configuration
└── package.json        # Project dependencies
```

## 🚢 Deployment

The site builds to a static bundle in the `dist` folder, ready for deployment to any static hosting service.

### Recommended Hosting Options

1. **Vercel** (Recommended)
```bash
make build
vercel deploy dist/
```

2. **Netlify**
```bash
make build
netlify deploy --dir=dist
```

3. **GitHub Pages**
```bash
make build
# Push dist/ folder to gh-pages branch
```

4. **Cloudflare Pages**
```bash
make build
# Connect to your GitHub repo in Cloudflare dashboard
```

## 📝 TODOs

### High Priority
- [ ] **Add Real App Screenshots**: Replace placeholder images in `src/components/Screenshots.jsx` with actual mobile app screenshots
- [ ] **Add Favicon Set**: Create and add favicon.ico, apple-touch-icon.png, and other favicon formats
- [ ] **Implement Email Capture**: Connect the email signup form to a backend service (e.g., Mailchimp, ConvertKit)

### Medium Priority
- [ ] **Add Analytics**: Implement privacy-respecting analytics (e.g., Plausible, Umami)
- [ ] **Create OG Image**: Design and add an Open Graph image for social sharing
- [ ] **Add Blog Section**: Create a blog/news section for updates
- [ ] **Implement Sitemap**: Generate sitemap.xml for better SEO

### Low Priority
- [ ] **Add Animations**: Enhance parallax effects and add more micro-interactions
- [ ] **Performance Optimization**: Implement lazy loading for images
- [ ] **A11y Improvements**: Add skip navigation links and improve screen reader support
- [ ] **Add Privacy Policy Page**: Create dedicated privacy policy and terms pages
- [ ] **Implement Cookie Banner**: Add GDPR-compliant cookie consent (if analytics added)
- [ ] **Add Press Kit**: Create a press/media kit section with logos and assets

## 🎨 Customization

### Updating Colors
Colors are defined in `tailwind.config.js` to match the mobile app. To update:

1. Edit the color values in `tailwind.config.js`
2. The color scheme uses the `aura-light` and `aura-dark` prefixes

### Adding New Sections
1. Create a new component in `src/components/`
2. Import and add it to `src/App.jsx`
3. Follow the existing component patterns for consistency

### Modifying Content
All text content is directly in the component files. Simply edit the JSX to update.

## 🐛 Troubleshooting

### Build Errors
If you encounter build errors:
```bash
make clean
make install
make build
```

### Port Already in Use
If port 5173 is already in use:
```bash
# Use a different port
bun run dev -- --port 3000
```

### Tailwind CSS Not Working
If styles aren't applying:
1. Check that classes are defined in `tailwind.config.js`
2. Restart the dev server after config changes
3. Clear browser cache

## 📜 License

AGPLv3 - See LICENSE file in the root directory for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request to the [GitHub repository](https://github.com/Aviat-IO/AuraOne).

## 📞 Support

For issues or questions:
- Open an issue on [GitHub](https://github.com/Aviat-IO/AuraOne/issues)
- Visit [auraone.me](https://auraone.me) for more information

---

Built with ❤️ for privacy advocates