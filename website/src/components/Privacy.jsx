import { motion } from 'framer-motion'
import { useInView } from 'react-intersection-observer'
import { Shield, HardDrive, Key, Download, Eye, Lock } from 'lucide-react'

const privacyFeatures = [
  {
    icon: HardDrive,
    title: "Local-First Storage",
    description: "All your data stays on your device. No cloud uploads, no server syncing. Your memories never leave your phone."
  },
  {
    icon: Key,
    title: "You Own Your Data",
    description: "Export your entire journal anytime in open formats. Switch apps or create backups - you're always in control."
  },
  {
    icon: Eye,
    title: "No Tracking",
    description: "We don't track you, analyze you, or sell your data. The app doesn't even have analytics. True privacy."
  },
  {
    icon: Lock,
    title: "End-to-End Encryption",
    description: "Optional encrypted backups ensure that even if you choose to backup, only you can read your journal."
  }
]

const Privacy = () => {
  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1
  })

  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8 relative">
      {/* Background decoration */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-gradient-to-r from-aura-light-primary/10 to-aura-light-tertiary/10 dark:from-aura-dark-primary/10 dark:to-aura-dark-tertiary/10 rounded-full blur-3xl" />
      </div>

      <div className="max-w-7xl mx-auto relative">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left side - Content */}
          <motion.div
            ref={ref}
            initial={{ opacity: 0, x: -50 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.6 }}
          >
            <div className="inline-flex items-center space-x-2 mb-4 px-4 py-2 rounded-full bg-aura-light-primary-container/50 dark:bg-aura-dark-primary-container/50">
              <Shield className="w-4 h-4 text-aura-light-on-primary-container dark:text-aura-dark-on-primary-container" />
              <span className="text-sm font-medium text-aura-light-on-primary-container dark:text-aura-dark-on-primary-container">
                Privacy First
              </span>
            </div>

            <h2 className="text-4xl sm:text-5xl font-bold mb-6">
              <span className="gradient-text from-aura-light-primary to-aura-light-tertiary dark:from-aura-dark-primary dark:to-aura-dark-tertiary">
                Your Memories,
              </span>
              <br />
              <span className="text-aura-light-on-surface dark:text-aura-dark-on-surface">
                Your Control
              </span>
            </h2>

            <p className="text-xl text-aura-light-on-surface/80 dark:text-aura-dark-on-surface/80 mb-8">
              In a world of cloud services and data mining, Aura One stands apart.
              We believe your personal journal should be truly personal.
            </p>

            <div className="space-y-6">
              {privacyFeatures.map((feature, index) => {
                const Icon = feature.icon
                return (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, y: 20 }}
                    animate={inView ? { opacity: 1, y: 0 } : {}}
                    transition={{ duration: 0.5, delay: index * 0.1 }}
                    className="flex space-x-4"
                  >
                    <div className="flex-shrink-0 w-12 h-12 rounded-xl bg-gradient-to-br from-aura-light-primary/20 to-aura-light-tertiary/20 dark:from-aura-dark-primary/20 dark:to-aura-dark-tertiary/20 flex items-center justify-center">
                      <Icon className="w-6 h-6 text-aura-light-primary dark:text-aura-dark-primary" />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-aura-light-on-surface dark:text-aura-dark-on-surface mb-1">
                        {feature.title}
                      </h3>
                      <p className="text-aura-light-on-surface/70 dark:text-aura-dark-on-surface/70">
                        {feature.description}
                      </p>
                    </div>
                  </motion.div>
                )
              })}
            </div>
          </motion.div>

          {/* Right side - Visual */}
          <motion.div
            initial={{ opacity: 0, x: 50 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="relative"
          >
            <div className="relative mx-auto max-w-md">
              {/* Shield visualization */}
              <motion.div
                animate={{
                  scale: [1, 1.05, 1],
                }}
                transition={{
                  duration: 3,
                  repeat: Infinity,
                  ease: "easeInOut"
                }}
                className="relative"
              >
                <div className="absolute inset-0 bg-gradient-to-br from-aura-light-primary/20 to-aura-light-tertiary/20 dark:from-aura-dark-primary/20 dark:to-aura-dark-tertiary/20 rounded-3xl blur-3xl" />

                <div className="relative bg-gradient-to-br from-aura-light-surface to-aura-light-surface-container dark:from-aura-dark-surface to-aura-dark-surface-container rounded-3xl p-8 soft-shadow-lg">
                  <div className="flex justify-center mb-6">
                    <div className="relative">
                      <Shield className="w-32 h-32 text-aura-light-primary dark:text-aura-dark-primary" />
                      <motion.div
                        animate={{
                          scale: [1, 1.2, 1],
                          opacity: [0.5, 1, 0.5],
                        }}
                        transition={{
                          duration: 2,
                          repeat: Infinity,
                          ease: "easeInOut"
                        }}
                        className="absolute inset-0 flex items-center justify-center"
                      >
                        <div className="w-40 h-40 bg-gradient-to-br from-aura-light-primary/30 to-aura-light-tertiary/30 dark:from-aura-dark-primary/30 dark:to-aura-dark-tertiary/30 rounded-full blur-2xl" />
                      </motion.div>
                    </div>
                  </div>

                  <div className="text-center">
                    <h3 className="text-2xl font-bold text-aura-light-on-surface dark:text-aura-dark-on-surface mb-2">
                      Zero Knowledge Architecture
                    </h3>
                    <p className="text-aura-light-on-surface/70 dark:text-aura-dark-on-surface/70">
                      We can't read your journal even if we wanted to. That's privacy by design.
                    </p>
                  </div>

                  {/* Privacy badges */}
                  <div className="flex justify-center space-x-4 mt-6">
                    <div className="px-3 py-1 rounded-full bg-aura-light-primary-container dark:bg-aura-dark-primary-container text-xs font-medium text-aura-light-on-primary-container dark:text-aura-dark-on-primary-container">
                      No Ads
                    </div>
                    <div className="px-3 py-1 rounded-full bg-aura-light-secondary-container dark:bg-aura-dark-secondary-container text-xs font-medium text-aura-light-on-secondary-container dark:text-aura-dark-on-secondary-container">
                      No Analytics
                    </div>
                    <div className="px-3 py-1 rounded-full bg-aura-light-tertiary-container dark:bg-aura-dark-tertiary-container text-xs font-medium text-aura-light-on-tertiary-container dark:text-aura-dark-on-tertiary-container">
                      No Tracking
                    </div>
                  </div>
                </div>
              </motion.div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}

export default Privacy