/** @type {import('tailwindcss').Config} */
module.exports = {
    // THIS CONTENT KEY WAS THE MISSING PIECE.
    // It tells Tailwind to scan all your files for classes.
    content: [
      './app/views/**/*.html.erb',
      './app/helpers/**/*.rb',
      './app/javascript/**/*.js',
      './app/assets/tailwind/application.css',
    ],
  
    theme: {
      // Everything custom must go inside 'extend'
      extend: {
  
        // This tells v4 what 'font-sans' means
        fontFamily: {
          sans: [
            'Inter',
            'ui-sans-serif',
            'system-ui',
            'sans-serif'
          ]
        },
  
        // This adds your custom TAMU colors
        colors: {
          'tamu-maroon': '#500000',
          'tamu-white': '#FFFFFF',
          'tamu-accent': '#8A6319',
          'tamu-gray': {
            '100': '#f7fafc',
            '200': '#edf2f7',
            '500': '#a0aec0',
            '700': '#4a5568',
            '800': '#2d3748',
          }
        }
      }
    },
    plugins: [
      require('@tailwindcss/forms'),
    ],
  }
  