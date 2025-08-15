// Dynamic Post Management System (File Protocol Compatible)
// This version works when opening index.html directly in browser

// Posts configuration - add new posts here
const POSTS = [
    {
        id: 'aws-free-tier-infrastructure',
        title: 'Building Enterprise Infrastructure on AWS Free Tier',
        date: '2024-12-15',
        tags: ['AWS', 'Terraform', 'DevOps'],
        excerpt: 'How I built this website with enterprise-grade features for under $2/month using AWS Free Tier, Terraform, and GitHub Actions. Complete with global CDN, HTTPS, automated deployments, and cost monitoring.',
        stats: [
            { label: '$0-2/month cost', icon: '💰' },
            { label: '<2s load time', icon: '⚡' },
            { label: 'Global CDN', icon: '🌍' }
        ],
        codeSnippet: `# Deploy this entire site
./scripts/validate.sh
terraform init && terraform apply

# Update content and deploy
git add . && git commit -m "new post"
git push  # Live globally in 2 minutes`
    },
    {
        id: 'kubernetes-development',
        title: 'Setting Up Local Kubernetes Development',
        date: '2024-11-28',
        tags: ['Kubernetes', 'Docker'],
        excerpt: 'A practical guide to setting up a local Kubernetes cluster for development. Using kind, kubectl, and some helpful scripts to make container development less painful.'
    },
    {
        id: 'github-actions-security',
        title: 'GitHub Actions Security Best Practices',
        date: '2024-11-15',
        tags: ['CI/CD', 'GitHub Actions'],
        excerpt: 'Lessons learned from implementing OIDC authentication and secure CI/CD pipelines. No more stored secrets, better security, and easier credential management.'
    },
    {
        id: 'cost-effective-monitoring',
        title: 'Cost-Effective Monitoring with Grafana',
        date: '2024-10-22',
        tags: ['Monitoring', 'Grafana'],
        excerpt: 'Building comprehensive monitoring without breaking the budget. Using Grafana Cloud\'s free tier and AWS CloudWatch to monitor everything that matters.'
    },
    {
        id: 'terraform-state-management',
        title: 'Terraform State Management Best Practices',
        date: '2024-10-08',
        tags: ['Terraform', 'DevOps'],
        excerpt: 'Managing Terraform state across teams and environments. Remote backends, locking, and strategies for avoiding state conflicts in production.'
    }
];

// Blog generation functions (File Protocol Compatible)
class BlogManager {
    constructor() {
        // Sort by timestamp if available, otherwise by date
        this.posts = POSTS.sort((a, b) => {
            const dateA = new Date(a.timestamp || a.date);
            const dateB = new Date(b.timestamp || b.date);
            return dateB - dateA;
        });
        
        // Automatically mark the most recent post as featured
        this.posts.forEach((post, index) => {
            post.featured = index === 0; // Only the first (most recent) post is featured
        });
    }

    // Format date for display
    formatDate(dateString) {
        const options = { year: 'numeric', month: 'short', day: 'numeric' };
        return new Date(dateString).toLocaleDateString('en-US', options);
    }

    // Generate post HTML
    generatePostHTML(post) {
        const featuredClass = post.featured ? 'post featured-post' : 'post';
        const featuredBadge = post.featured ? '<div class="featured-badge">Latest</div>' : '';
        
        const statsHTML = post.stats ? `
            <div class="post-stats">
                ${post.stats.map(stat => `
                    <span class="stat-item">
                        <span>${stat.icon}</span>
                        <span>${stat.label}</span>
                    </span>
                `).join('')}
            </div>
        ` : '';

        const codeSnippetHTML = post.codeSnippet ? `
            <div class="code-snippet">
                <pre><code>${this.escapeHtml(post.codeSnippet)}</code></pre>
            </div>
        ` : '';

        return `
            <article class="${featuredClass}">
                ${featuredBadge}
                <div class="post-meta">
                    <span class="post-date">${this.formatDate(post.date)}</span>
                    ${post.tags.map(tag => `<span class="post-tag">${tag}</span>`).join('')}
                </div>
                <h2><a href="posts/${post.id}.html">${post.title}</a></h2>
                <p class="post-excerpt">${post.excerpt}</p>
                ${statsHTML}
                ${codeSnippetHTML}
                <a href="posts/${post.id}.html" class="read-more">Read full post →</a>
            </article>
        `;
    }

    // Escape HTML to prevent XSS
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    // Generate recent posts for sidebar
    generateRecentPostsHTML() {
        return this.posts.slice(0, 5).map(post => 
            `<li><a href="posts/${post.id}.html">${post.title}</a></li>`
        ).join('');
    }

    // Generate unique tags
    generateTagsHTML() {
        const allTags = this.posts.flatMap(post => post.tags);
        const uniqueTags = [...new Set(allTags)];
        
        return uniqueTags.map(tag => 
            `<a href="#" class="tag" data-tag="${tag}">${tag}</a>`
        ).join('');
    }

    // Render the blog (works with file:// protocol)
    renderBlog() {
        // Wait for DOM to be ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.renderBlog());
            return;
        }

        const mainContent = document.querySelector('.main-content');
        const recentPostsList = document.querySelector('.recent-posts');
        const tagsContainer = document.querySelector('.tags');

        if (mainContent) {
            mainContent.innerHTML = this.posts.map(post => this.generatePostHTML(post)).join('');
        }

        if (recentPostsList) {
            recentPostsList.innerHTML = this.generateRecentPostsHTML();
        }

        if (tagsContainer) {
            tagsContainer.innerHTML = this.generateTagsHTML();
        }

        // Add tag filtering
        this.initTagFiltering();

        // Add animation observer
        this.initScrollAnimations();
    }

    // Initialize tag filtering
    initTagFiltering() {
        const tagElements = document.querySelectorAll('.tag[data-tag]');
        
        tagElements.forEach(tagEl => {
            tagEl.addEventListener('click', (e) => {
                e.preventDefault();
                const selectedTag = e.target.dataset.tag;
                this.filterByTag(selectedTag);
                
                // Update active tag styling
                tagElements.forEach(el => el.classList.remove('active'));
                e.target.classList.add('active');
            });
        });

        // Add "All" option
        const allTag = document.createElement('a');
        allTag.href = '#';
        allTag.className = 'tag active';
        allTag.textContent = 'All';
        allTag.addEventListener('click', (e) => {
            e.preventDefault();
            this.renderBlog();
            tagElements.forEach(el => el.classList.remove('active'));
            allTag.classList.add('active');
        });
        
        const tagsContainer = document.querySelector('.tags');
        if (tagsContainer) {
            tagsContainer.insertBefore(allTag, tagsContainer.firstChild);
        }
    }

    // Filter posts by tag
    filterByTag(tag) {
        const filteredPosts = this.posts.filter(post => post.tags.includes(tag));
        const mainContent = document.querySelector('.main-content');
        
        if (mainContent) {
            mainContent.innerHTML = filteredPosts.map(post => this.generatePostHTML(post)).join('');
            this.initScrollAnimations(); // Re-init animations for filtered posts
        }
    }

    // Animation on scroll
    initScrollAnimations() {
        // Check if IntersectionObserver is supported
        if (!window.IntersectionObserver) return;

        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                }
            });
        }, observerOptions);

        // Animate posts on scroll
        document.querySelectorAll('.post').forEach(el => {
            el.style.opacity = '0';
            el.style.transform = 'translateY(20px)';
            el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
            observer.observe(el);
        });
    }

    // Get post by ID (useful for article pages)
    getPost(id) {
        return this.posts.find(post => post.id === id);
    }

    // Get related posts (by shared tags)
    getRelatedPosts(currentPostId, limit = 3) {
        const currentPost = this.getPost(currentPostId);
        if (!currentPost) return [];

        const relatedPosts = this.posts
            .filter(post => post.id !== currentPostId)
            .map(post => ({
                ...post,
                relevance: post.tags.filter(tag => currentPost.tags.includes(tag)).length
            }))
            .filter(post => post.relevance > 0)
            .sort((a, b) => b.relevance - a.relevance)
            .slice(0, limit);

        return relatedPosts;
    }
}

// Initialize blog when script loads (works with file:// protocol)
(function() {
    // Only run on blog pages (not article pages)
    if (document.querySelector('.blog-container')) {
        const blogManager = new BlogManager();
        
        // Try to render immediately if DOM is ready
        if (document.readyState !== 'loading') {
            blogManager.renderBlog();
        } else {
            // Wait for DOM to be ready
            document.addEventListener('DOMContentLoaded', () => {
                blogManager.renderBlog();
            });
        }
        
        // Make blog manager globally available
        window.blogManager = blogManager;
    }
})();