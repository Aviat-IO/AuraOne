import { Github, Twitter, Mail, Heart } from 'lucide-react'

const Footer = () => {
  const currentYear = new Date().getFullYear()

  const links = {
    product: [
      { name: "Features", href: "#features" },
      { name: "Privacy", href: "#privacy" },
      { name: "Open Source", href: "#opensource" },
    ],
    resources: [
      { name: "Documentation", href: "https://github.com/Aviat-IO/AuraOne/wiki" },
      { name: "GitHub", href: "https://github.com/Aviat-IO/AuraOne" },
      { name: "Releases", href: "https://github.com/Aviat-IO/AuraOne/releases" },
    ],
    company: [
      { name: "About", href: "#" },
      { name: "Blog", href: "#" },
      { name: "Contact", href: "#" },
    ],
    legal: [
      { name: "Privacy Policy", href: "#" },
      { name: "Terms of Service", href: "#" },
      { name: "License (AGPLv3)", href: "https://github.com/Aviat-IO/AuraOne/blob/main/LICENSE" },
    ]
  }

  return (
    <footer className="pt-20 pb-8 px-4 sm:px-6 lg:px-8 border-t border-aura-light-outline-variant dark:border-aura-dark-outline-variant">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-8 mb-12">
          {/* Brand section */}
          <div className="lg:col-span-1">
            <div className="flex items-center space-x-2 mb-4">
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-aura-light-primary to-aura-light-tertiary dark:from-aura-dark-primary dark:to-aura-dark-tertiary" />
              <span className="text-xl font-semibold text-aura-light-on-surface dark:text-aura-dark-on-surface">
                Aura One
              </span>
            </div>
            <p className="text-sm text-aura-light-on-surface/60 dark:text-aura-dark-on-surface/60 mb-4">
              Your life, automatically chronicled. Private, local-first journaling powered by AI.
            </p>
            <div className="flex space-x-3">
              <a
                href="https://github.com/Aviat-IO/AuraOne"
                target="_blank"
                rel="noopener noreferrer"
                className="p-2 rounded-lg hover:bg-aura-light-surface-high dark:hover:bg-aura-dark-surface-high transition-colors"
                aria-label="GitHub"
              >
                <Github className="w-5 h-5 text-aura-light-on-surface/60 dark:text-aura-dark-on-surface/60" />
              </a>
              <a
                href="#"
                className="p-2 rounded-lg hover:bg-aura-light-surface-high dark:hover:bg-aura-dark-surface-high transition-colors"
                aria-label="Twitter"
              >
                <Twitter className="w-5 h-5 text-aura-light-on-surface/60 dark:text-aura-dark-on-surface/60" />
              </a>
              <a
                href="#"
                className="p-2 rounded-lg hover:bg-aura-light-surface-high dark:hover:bg-aura-dark-surface-high transition-colors"
                aria-label="Email"
              >
                <Mail className="w-5 h-5 text-aura-light-on-surface/60 dark:text-aura-dark-on-surface/60" />
              </a>
            </div>
          </div>

          {/* Links sections */}
          <div>
            <h3 className="text-sm font-semibold text-aura-light-on-surface dark:text-aura-dark-on-surface mb-4">
              Product
            </h3>
            <ul className="space-y-2">
              {links.product.map((link) => (
                <li key={link.name}>
                  <a
                    href={link.href}
                    className="text-sm text-aura-light-on-surface/60 dark:text-aura-dark-on-surface/60 hover:text-aura-light-primary dark:hover:text-aura-dark-primary transition-colors"
                  >
                    {link.name}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h3 className="text-sm font-semibold text-aura-light-on-surface dark:text-aura-dark-on-surface mb-4">
              Resources
            </h3>
            <ul className="space-y-2">
              {links.resources.map((link) => (
                <li key={link.name}>
                  <a
                    href={link.href}
                    className="text-sm text-aura-light-on-surface/60 dark:text-aura-dark-on-surface/60 hover:text-aura-light-primary dark:hover:text-aura-dark-primary transition-colors"
                  >
                    {link.name}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h3 className="text-sm font-semibold text-aura-light-on-surface dark:text-aura-dark-on-surface mb-4">
              Company
            </h3>
            <ul className="space-y-2">
              {links.company.map((link) => (
                <li key={link.name}>
                  <a
                    href={link.href}
                    className="text-sm text-aura-light-on-surface/60 dark:text-aura-dark-on-surface/60 hover:text-aura-light-primary dark:hover:text-aura-dark-primary transition-colors"
                  >
                    {link.name}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h3 className="text-sm font-semibold text-aura-light-on-surface dark:text-aura-dark-on-surface mb-4">
              Legal
            </h3>
            <ul className="space-y-2">
              {links.legal.map((link) => (
                <li key={link.name}>
                  <a
                    href={link.href}
                    className="text-sm text-aura-light-on-surface/60 dark:text-aura-dark-on-surface/60 hover:text-aura-light-primary dark:hover:text-aura-dark-primary transition-colors"
                  >
                    {link.name}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Bottom section */}
        <div className="pt-8 border-t border-aura-light-outline-variant dark:border-aura-dark-outline-variant">
          <div className="flex flex-col sm:flex-row justify-between items-center">
            <p className="text-sm text-aura-light-on-surface/60 dark:text-aura-dark-on-surface/60 mb-4 sm:mb-0">
              © {currentYear} Aura One. All rights reserved. Licensed under AGPLv3.
            </p>
            <div className="flex items-center space-x-1 text-sm text-aura-light-on-surface/60 dark:text-aura-dark-on-surface/60">
              <span>Made with</span>
              <Heart className="w-4 h-4 text-aura-light-primary dark:text-aura-dark-primary fill-current" />
              <span>for privacy advocates</span>
            </div>
          </div>
        </div>
      </div>
    </footer>
  )
}

export default Footer