import { motion } from 'framer-motion'
import { useInView } from 'react-intersection-observer'
import {
  BookOpen,
  MapPin,
  Camera,
  Calendar,
  Mic,
  TrendingUp,
  Download,
  Lock
} from 'lucide-react'

const features = [
  {
    icon: BookOpen,
    title: "Automatic Daily Entries",
    description: "Your day is automatically documented from your activities, photos, and locations. No more blank pages or writer's block.",
    gradient: "from-aura-light-primary to-aura-light-secondary dark:from-aura-dark-primary dark:to-aura-dark-secondary"
  },
  {
    icon: MapPin,
    title: "Location Tracking",
    description: "Remember where you've been with automatic location capture. See your day's journey mapped out beautifully.",
    gradient: "from-aura-light-secondary to-aura-light-tertiary dark:from-aura-dark-secondary dark:to-aura-dark-tertiary"
  },
  {
    icon: Camera,
    title: "Photo Integration",
    description: "Automatically include photos from your day. Your visual memories seamlessly woven into your journal.",
    gradient: "from-aura-light-tertiary to-aura-light-primary dark:from-aura-dark-tertiary dark:to-aura-dark-primary"
  },
  {
    icon: Calendar,
    title: "Calendar Sync",
    description: "Your appointments and events automatically added to provide context to your daily narrative.",
    gradient: "from-aura-light-primary to-aura-light-tertiary dark:from-aura-dark-primary dark:to-aura-dark-tertiary"
  },
  {
    icon: Mic,
    title: "Voice Editing",
    description: "Edit your entries with voice commands. Just speak naturally to refine your journal.",
    gradient: "from-aura-light-secondary to-aura-light-primary dark:from-aura-dark-secondary dark:to-aura-dark-primary"
  },
  {
    icon: TrendingUp,
    title: "AI Insights",
    description: "Discover patterns in your life with AI analysis. Understand your habits and emotions over time.",
    gradient: "from-aura-light-tertiary to-aura-light-secondary dark:from-aura-dark-tertiary dark:to-aura-dark-secondary"
  },
  {
    icon: Download,
    title: "Export Anywhere",
    description: "Your data, your control. Export your entire journal in open formats anytime.",
    gradient: "from-aura-light-primary to-aura-light-secondary dark:from-aura-dark-primary dark:to-aura-dark-secondary"
  },
  {
    icon: Lock,
    title: "100% Private",
    description: "All data stays on your device. No cloud uploads, no data mining. Your memories are yours alone.",
    gradient: "from-aura-light-secondary to-aura-light-tertiary dark:from-aura-dark-secondary dark:to-aura-dark-tertiary"
  }
]

const FeatureCard = ({ feature, index }) => {
  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1
  })

  const Icon = feature.icon

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 20 }}
      animate={inView ? { opacity: 1, y: 0 } : {}}
      transition={{ duration: 0.5, delay: index * 0.1 }}
      whileHover={{ y: -5 }}
      className="group relative"
    >
      <div className="absolute inset-0 bg-gradient-to-r opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-2xl blur-xl -z-10"
           style={{
             background: `linear-gradient(to right, var(--tw-gradient-from), var(--tw-gradient-to))`
           }}
      />

      <div className="relative p-6 rounded-2xl bg-white/50 dark:bg-aura-dark-surface-container/50 backdrop-blur-sm border border-aura-light-outline-variant dark:border-aura-dark-outline-variant">
        <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${feature.gradient} flex items-center justify-center mb-4`}>
          <Icon className="w-6 h-6 text-white" />
        </div>

        <h3 className="text-xl font-semibold text-aura-light-on-surface dark:text-aura-dark-on-surface mb-2">
          {feature.title}
        </h3>

        <p className="text-aura-light-on-surface/70 dark:text-aura-dark-on-surface/70">
          {feature.description}
        </p>
      </div>
    </motion.div>
  )
}

const Features = () => {
  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          transition={{ duration: 0.6 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl sm:text-5xl font-bold mb-4">
            <span className="gradient-text from-aura-light-primary to-aura-light-tertiary dark:from-aura-dark-primary dark:to-aura-dark-tertiary">
              Effortless Journaling,
            </span>
            <br />
            <span className="text-aura-light-on-surface dark:text-aura-dark-on-surface">
              Powerful Insights
            </span>
          </h2>
          <p className="text-xl text-aura-light-on-surface/70 dark:text-aura-dark-on-surface/70 max-w-2xl mx-auto">
            Let Aura One capture your life automatically while you focus on living it
          </p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {features.map((feature, index) => (
            <FeatureCard key={index} feature={feature} index={index} />
          ))}
        </div>
      </div>
    </section>
  )
}

export default Features