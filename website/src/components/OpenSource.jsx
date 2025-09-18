import { motion } from 'framer-motion'
import { useInView } from 'react-intersection-observer'
import { Github, Code, Users, Heart, GitBranch, Star } from 'lucide-react'

const OpenSource = () => {
  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1
  })

  const stats = [
    { icon: Star, label: "Stars", value: "Coming Soon" },
    { icon: GitBranch, label: "Forks", value: "Join Us" },
    { icon: Users, label: "Contributors", value: "Be First" }
  ]

  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        <motion.div
          ref={ref}
          initial={{ opacity: 0, y: 20 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="text-center mb-12"
        >
          <div className="inline-flex items-center space-x-2 mb-4 px-4 py-2 rounded-full bg-aura-light-tertiary-container/50 dark:bg-aura-dark-tertiary-container/50">
            <Code className="w-4 h-4 text-aura-light-on-tertiary-container dark:text-aura-dark-on-tertiary-container" />
            <span className="text-sm font-medium text-aura-light-on-tertiary-container dark:text-aura-dark-on-tertiary-container">
              Open Source
            </span>
          </div>

          <h2 className="text-4xl sm:text-5xl font-bold mb-6">
            <span className="text-aura-light-on-surface dark:text-aura-dark-on-surface">
              Built in the Open,
            </span>
            <br />
            <span className="gradient-text from-aura-light-primary to-aura-light-tertiary dark:from-aura-dark-primary dark:to-aura-dark-tertiary">
              For Everyone
            </span>
          </h2>

          <p className="text-xl text-aura-light-on-surface/80 dark:text-aura-dark-on-surface/80 max-w-3xl mx-auto mb-8">
            Aura One is completely open source. Review the code, contribute features,
            or fork it to create your own version. This is software that respects you.
          </p>

          {/* GitHub stats */}
          <div className="flex justify-center space-x-8 mb-12">
            {stats.map((stat, index) => {
              const Icon = stat.icon
              return (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, y: 20 }}
                  animate={inView ? { opacity: 1, y: 0 } : {}}
                  transition={{ duration: 0.5, delay: index * 0.1 }}
                  className="text-center"
                >
                  <Icon className="w-6 h-6 text-aura-light-primary dark:text-aura-dark-primary mx-auto mb-2" />
                  <div className="text-2xl font-bold text-aura-light-on-surface dark:text-aura-dark-on-surface">
                    {stat.value}
                  </div>
                  <div className="text-sm text-aura-light-on-surface/60 dark:text-aura-dark-on-surface/60">
                    {stat.label}
                  </div>
                </motion.div>
              )
            })}
          </div>

          {/* Code preview */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={inView ? { opacity: 1, scale: 1 } : {}}
            transition={{ duration: 0.6, delay: 0.3 }}
            className="relative max-w-4xl mx-auto"
          >
            <div className="absolute inset-0 bg-gradient-to-r from-aura-light-primary/20 to-aura-light-tertiary/20 dark:from-aura-dark-primary/20 dark:to-aura-dark-tertiary/20 rounded-2xl blur-3xl" />

            <div className="relative bg-gray-900 rounded-2xl p-6 soft-shadow-lg">
              <div className="flex items-center space-x-2 mb-4">
                <div className="w-3 h-3 rounded-full bg-red-500" />
                <div className="w-3 h-3 rounded-full bg-yellow-500" />
                <div className="w-3 h-3 rounded-full bg-green-500" />
              </div>

              <pre className="text-sm text-gray-300 overflow-x-auto">
                <code>{`// Aura One - Your Life, Automatically Chronicled
// Licensed under AGPLv3 - Your freedom guaranteed

class AuraOne {
  constructor() {
    this.privacy = 'local-first';
    this.ownership = 'user-controlled';
    this.license = 'AGPLv3';
  }

  captureDay() {
    // Your memories, captured automatically
    const memories = await this.gatherActivities();
    const summary = await this.generateSummary(memories);
    return this.saveLocally(summary);
  }
}`}</code>
              </pre>
            </div>
          </motion.div>

          {/* CTA */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={inView ? { opacity: 1 } : {}}
            transition={{ duration: 0.6, delay: 0.5 }}
            className="mt-12"
          >
            <a
              href="https://github.com/Aviat-IO/AuraOne"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center space-x-2 px-6 py-3 rounded-xl bg-gradient-to-r from-aura-light-primary to-aura-light-tertiary dark:from-aura-dark-primary dark:to-aura-dark-tertiary text-white font-semibold hover:scale-105 transition-transform"
            >
              <Github className="w-5 h-5" />
              <span>View on GitHub</span>
            </a>

            <div className="mt-6 flex justify-center space-x-8">
              <div className="flex items-center space-x-2 text-aura-light-on-surface/60 dark:text-aura-dark-on-surface/60">
                <Heart className="w-4 h-4" />
                <span className="text-sm">Made with love</span>
              </div>
              <div className="flex items-center space-x-2 text-aura-light-on-surface/60 dark:text-aura-dark-on-surface/60">
                <Code className="w-4 h-4" />
                <span className="text-sm">100% Open Source</span>
              </div>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  )
}

export default OpenSource