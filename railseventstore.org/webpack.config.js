const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const path = require("path");

module.exports = {
  output: {
    path: path.resolve(__dirname, "source/stylesheets")
  },
  entry: "./source/stylesheets/styles.css",
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, "css-loader", "postcss-loader"]
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: "site.css"
    })
  ]
};
