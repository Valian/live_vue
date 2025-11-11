import antfu from '@antfu/eslint-config'

export default antfu(
  {
    ignores: ['.github/', '**/*.md'],
    gitignore: {
      files: ['.gitignore', 'example_project/.gitignore'],
    },
    typescript: true,
    vue: true,
  },
  {
    files: ['**/test/**/*.{js,ts,vue}', '**/*.test.{js,ts}'],
    rules: {
      'no-console': 'off',
    },
  },
)
