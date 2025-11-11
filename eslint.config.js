import antfu from '@antfu/eslint-config'

export default antfu(
  {
    ignores: [
      '.github/',
      '**/*.md',
      '**/test/**',
      '**/*.test.{js,ts}',
    ],
    typescript: true,
    vue: true,
  },
)
