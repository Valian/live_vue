import antfu from '@antfu/eslint-config'

export default antfu(
  {
    ignores: ['.github/', '**/*.md'],
    gitignore: {
      files: ['.gitignore', 'example_project/.gitignore'],
    },
    typescript: {
      overrides: {
        'ts/consistent-type-definitions': 'off',
      },
    },
    vue: {
      overrides: {
        'vue/no-unused-properties': 'warn',
        'vue/prop-name-casing': 'off',
      },
    },
  },
  {
    files: ['**/test/**/*.{js,ts,vue}', '**/*.test.{js,ts}'],
    rules: {
      'no-console': 'off',
    },
  },
)
