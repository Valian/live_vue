import antfu from '@antfu/eslint-config'

export default antfu(
  {
    ignores: [
      '.github/',
      '**/*.md',
      '**/test/**/*.*',
      '**/*.test.{js,ts}',
    ],
    gitignore: {
      files: ['.gitignore', 'example_project/.gitignore'],
    },
    typescript: true,
    vue: true,
  },
)
