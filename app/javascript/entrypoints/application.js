import 'core-js/stable'
import PulfalightLoader from '@/pulfalight/pulfalight_loader.es6'

document.addEventListener('DOMContentLoaded', () => {
  // Load components
  const loader = new PulfalightLoader()
  loader.run()
})
