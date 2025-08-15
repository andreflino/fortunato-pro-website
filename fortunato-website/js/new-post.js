#!/usr/bin/env node

// New Post Generator Script
// Usage: node new-post.js "Post Title" "post-slug" "tag1,tag2,tag3"

const fs = require('fs');
const path = require('path');

function generatePostTemplate(title, slug, tags, excerpt = '') {
    const date = new Date().toISOString().split('T')[0];
    const tagsArray = tags.split(',').map(tag => tag.trim());
    
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title} - Fortunato.pro</title>
    <link rel="stylesheet" href="../css/styles.css">
    <link rel="stylesheet" href="../css/article.css">
</head>
<body>
    <header>
        <nav class="container">
            <a href="../index.html" class="logo">fortunato.pro</a>
            <div class="nav-right">
                <ul class="nav-links">
                    <li><a href="../index.html">Home</a></li>
                    <li><a href="../index.html#about">About</a></li>
                    <li><a href="../index.html#projects">Projects</a></li>
                    <li><a href="../index.html#contact">Contact</a></li>
                </ul>
                <button class="theme-toggle" id="theme-toggle" aria-label="Toggle theme">
                    <span class="theme-icon">🌙</span>
                </button>
            </div>
        </nav>
    </header>

    <main class="container article">
        <article class="article-container">
            <a href="../index.html" class="back-link">← Back to blog</a>
            
            <header class="article-header">
                <div class="article-meta">
                    <span>${new Date(date).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })}</span>
                    ${tagsArray.map(tag => `<span class="article-tag">${tag}</span>`).join('\n                    ')}
                </div>
                <h1 class="article-title">${title}</h1>
                <p class="article-subtitle">Add your subtitle here</p>
            </header>

            <div class="article-content">
                <p>Write your article content here...</p>

                <h2>Section Header</h2>
                
                <p>Your content continues here. You can use:</p>
                
                <ul>
                    <li>Bullet points</li>
                    <li>Code blocks</li>
                    <li>Images</li>
                    <li>And more</li>
                </ul>

                <div class="code-block">
<span class="highlight"># Example code block</span>
echo "Hello, world!"
                </div>

                <div class="callout">
                    <h4>Pro Tip</h4>
                    <p>Use callouts to highlight important information.</p>
                </div>

                <h3>Subsection</h3>
                
                <p>Continue writing your article...</p>
            </div>
        </article>
    </main>

    <footer>
        <div class="container">
            <p>&copy; 2024 fortunato.pro - Built with AWS Free Tier</p>
        </div>
    </footer>

    <script src="../js/theme.js"></script>
</body>
</html>`;
}

function generatePostConfig(title, slug, tags, excerpt = '') {
    const now = new Date();
    const date = now.toISOString().split('T')[0]; // Just the date part
    const timestamp = now.toISOString(); // Full timestamp with time
    const tagsArray = tags.split(',').map(tag => tag.trim());
    
    return `    {
        id: '${slug}',
        title: '${title}',
        date: '${date}',
        timestamp: '${timestamp}',
        tags: [${tagsArray.map(tag => `'${tag}'`).join(', ')}],
        excerpt: '${excerpt || 'Add your post excerpt here...'}'
    },`;
}

function main() {
    const args = process.argv.slice(2);
    
    if (args.length < 2) {
        console.log('Usage: node new-post.js "Post Title" "post-slug" "tag1,tag2,tag3" "Optional excerpt"');
        console.log('Example: node new-post.js "Docker Best Practices" "docker-best-practices" "Docker,DevOps" "Tips for better Docker workflows"');
        process.exit(1);
    }

    const [title, slug, tags = 'DevOps', excerpt = ''] = args;
    
    // Create posts directory if it doesn't exist
    const postsDir = path.join(__dirname, '..', 'posts');
    if (!fs.existsSync(postsDir)) {
        fs.mkdirSync(postsDir);
        console.log('Created posts directory');
    }

    // Generate HTML file
    const htmlContent = generatePostTemplate(title, slug, tags, excerpt);
    const htmlPath = path.join(postsDir, `${slug}.html`);
    
    if (fs.existsSync(htmlPath)) {
        console.log(`Warning: ${htmlPath} already exists!`);
        process.exit(1);
    }

    fs.writeFileSync(htmlPath, htmlContent);
    console.log(`Created: ${htmlPath}`);

    // Generate config entry
    const configEntry = generatePostConfig(title, slug, tags, excerpt);
    console.log('\nAdd this to your posts.js POSTS array:');
    console.log(configEntry);
    
    console.log(`\nNext steps:
1. Edit posts/${slug}.html with your content
2. Add the config entry above to js/posts.js
3. Commit and push your changes`);
}

if (require.main === module) {
    main();
}