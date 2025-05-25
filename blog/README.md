# Agent Blog

A minimal Hugo blog site exploring AI agents, development practices, and the intersection of technology and automation.

## Overview

This blog is built with [Hugo](https://gohugo.io/) using the [Blowfish](https://blowfish.page/) theme. It features a clean, minimal design focused on content readability and fast loading times.

## Features

- **Hugo Static Site Generator** - Fast, secure, and SEO-friendly
- **Blowfish Theme** - Modern, responsive design with dark/light mode support
- **TailwindCSS** - Utility-first CSS framework for styling
- **Hugo Modules** - Theme management via Hugo modules
- **Syntax Highlighting** - Code blocks with proper highlighting
- **Responsive Design** - Works on all devices
- **Fast Loading** - Optimized for performance

## Prerequisites

- [Hugo](https://gohugo.io/installation/) (v0.87.0 or later)
- [Go](https://golang.org/dl/) (for Hugo modules)
- [Git](https://git-scm.com/) (for version control)

## Quick Start

### 1. Clone and Navigate

```bash
git clone <repository-url>
cd blog
```

### 2. Install Dependencies

Hugo will automatically download the theme module on first build:

```bash
hugo mod get
```

### 3. Run Development Server

```bash
hugo server --buildDrafts
```

The site will be available at `http://localhost:1313`

### 4. Build for Production

```bash
hugo
```

The built site will be in the `public/` directory.

## Project Structure

```
blog/
├── config/
│   └── _default/
│       ├── hugo.toml          # Main Hugo configuration
│       ├── languages.en.toml  # Language-specific settings
│       ├── module.toml        # Hugo modules configuration
│       └── params.toml        # Theme parameters
├── content/
│   ├── _index.md              # Homepage content
│   └── posts/                 # Blog posts
│       ├── _index.md          # Posts section page
│       └── *.md               # Individual blog posts
├── go.mod                     # Go modules file
├── go.sum                     # Go modules checksums
└── README.md                  # This file
```

## Configuration

### Main Configuration (`config/_default/hugo.toml`)

- **baseURL**: Set your production URL
- **languageCode**: Primary language (currently "en")
- **title**: Site title
- **permalinks**: URL structure for posts

### Theme Configuration (`config/_default/params.toml`)

- **colorScheme**: Theme color scheme
- **homepage.layout**: Homepage layout style
- **article**: Post display settings
- **list**: Archive page settings

### Language Configuration (`config/_default/languages.en.toml`)

- **author**: Author information
- **menu**: Navigation menu items

## Content Management

### Creating New Posts

1. Create a new markdown file in `content/posts/`:

```bash
hugo new content/posts/my-new-post.md
```

2. Edit the front matter and content:

```yaml
---
title: "My New Post"
date: 2025-01-23T10:00:00-06:00
slug: "my-new-post"
categories:
  - development
tags:
  - hugo
  - blogging
summary: "A brief description of the post"
---

Your content here...
```

### Front Matter Fields

- **title**: Post title
- **date**: Publication date (ISO 8601 format)
- **slug**: URL slug (optional, defaults to filename)
- **categories**: Post categories
- **tags**: Post tags
- **summary**: Brief description for listings
- **draft**: Set to `true` for draft posts

## Development Workflow

### Local Development

```bash
# Start development server with drafts
hugo server --buildDrafts

# Start server on different port
hugo server --port 8080

# Start server with live reload disabled
hugo server --disableLiveReload
```

### Building

```bash
# Build for production
hugo

# Build with drafts included
hugo --buildDrafts

# Build for specific environment
hugo --environment production
```

### Theme Updates

```bash
# Update theme to latest version
hugo mod get -u github.com/nunocoracao/blowfish/v2

# Clean module cache
hugo mod clean
```

## Customization

### Styling

The Blowfish theme uses TailwindCSS. You can customize styles by:

1. Modifying theme parameters in `config/_default/params.toml`
2. Creating custom CSS in `assets/css/custom.css`
3. Overriding theme templates in `layouts/`

### Theme Parameters

Key customization options in `params.toml`:

```toml
# Color scheme
colorScheme = "blowfish"
defaultAppearance = "light"
autoSwitchAppearance = true

# Homepage layout
homepage.layout = "page"

# Article settings
[article]
showDate = true
showAuthor = true
showReadingTime = true
showSummary = true
```

## Deployment

### Static Hosting

The built site in `public/` can be deployed to any static hosting service:

- **Netlify**: Connect your Git repository for automatic deployments
- **Vercel**: Import your project for instant deployments
- **GitHub Pages**: Use GitHub Actions for automated builds
- **AWS S3**: Upload the `public/` directory to an S3 bucket

### Build Command

For most hosting services, use:

```bash
hugo --minify
```

## Troubleshooting

### Common Issues

1. **Theme not found**: Ensure Hugo modules are properly initialized
   ```bash
   hugo mod init github.com/your-username/your-repo
   hugo mod get
   ```

2. **Build errors**: Check Hugo version compatibility
   ```bash
   hugo version
   ```

3. **Module issues**: Clean and reinstall modules
   ```bash
   hugo mod clean
   hugo mod get
   ```

### Getting Help

- [Hugo Documentation](https://gohugo.io/documentation/)
- [Blowfish Theme Docs](https://blowfish.page/docs/)
- [Hugo Community Forum](https://discourse.gohugo.io/)

## License

This blog content and configuration are available under the MIT License. The Blowfish theme has its own license terms. 
