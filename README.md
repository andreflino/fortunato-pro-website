# fortunato-pro-website

A personal website running on AWS Free Tier. Built this to practice DevOps without breaking the bank.

## What it is

A static website with proper infrastructure - CloudFront CDN, HTTPS, automated deployments, the works. Costs me basically nothing ($0-2/month) but performs like expensive hosting.

## Why I built this

- Wanted to show how Infrastructure as Code works properly
- Tired of paying $10+/month for simple hosting
- Needed a portfolio project that shows real DevOps skills
- AWS Free Tier is generous if you know how to use it - Take a look at Lambdas as well
- Why AWS? Good question. It could be Azure, but I chose AWS.

## Infra Features

- **Global CDN** - CloudFront makes it fast everywhere
- **HTTPS** - Real SSL cert, not self-signed junk
- **No stored AWS keys** - Uses OIDC, way more secure
- **Auto deploy** - Push to GitHub, live in 2 minutes
- **Cost monitoring** - Alerts if I'm spending too much
- **Infrastructure as Code** - Everything in Terraform
- **Dynamic blog system** - Because I got tired of manually updating HTML
- **Dark/light theme** - Because apparently that's mandatory in 2024

## Site Structure & Blog System

Turns out building a blog from scratch was more fun than using WordPress (controversial comment).

### Blog Features
- **Automatic post discovery** - Add posts to a config file, magic happens
- **Theme toggle** - Dark mode for the cool kids, light mode for readability
- **Tag filtering** - Click tags to filter posts (fancy!)
- **Auto "Latest" badge** - The newest post gets bragging rights automatically
- **Responsive design** - Because everyone reads on their phone

### Creating New Posts

I built a script because I'm lazy and hate repetitive tasks.

#### Method 1: Auto-generation (For the impatient)
```bash
# Generate new post template
node js/new-post.js "Post Title" "post-slug" "tag1,tag2" "Post excerpt"

# Example:
node js/new-post.js "Docker Best Practices" "docker-best-practices" "Docker,DevOps" "Essential tips for better containers"
```

This creates:
- **HTML file**: Ready-to-edit template in `posts/`
- **Config entry**: Copy-paste into `js/posts.js`  # I'm goint to automate this at some point as well
- **No headaches**: Which is the real value here

#### Method 2: Manual Creation
1. Create HTML file in `posts/` folder
2. Add post entry to `js/posts.js` 
3. Follow the existing structure
4. Wonder why you didn't use the script

### Post Configuration
Posts live in `js/posts.js` because everything is JavaScript now: 

```javascript
{
    id: 'your-post-slug',
    title: 'Your Post Title',
    date: '2024-12-16',
    timestamp: '2024-12-16T14:30:00.000Z', // For when you write 5 posts in one day
    tags: ['Tag1', 'Tag2'],
    excerpt: 'Brief description that makes people want to read more...'
}
```

The system automatically:
- **Sorts posts by date** - Newest first, obviously
- **Marks latest post** - "Latest" badge goes to the most recent
- **Generates sidebar** - Recent posts list updates itself
- **Creates tag filters** - Click and filter, it just works

## Setup

You'll need AWS CLI and Terraform. If you don't have them, Google is your friend.

```bash
git clone https://github.com/yourusername/fortunato-pro-website.git
cd fortunato-pro-website

# Update with your domain/settings
nano config/site.yaml

# Set up AWS (one time setup, then forget about it)
aws configure
```

Deploy the infrastructure:

```bash
# Check everything looks good (paranoia pays off)
./scripts/validate.sh

# See what it'll cost
./scripts/check-costs.sh

# Create S3 bucket for state (one-time setup)
aws s3 mb s3://your-name-terraform-state --region us-east-1

# Create DynamoDB table for locking (optional but recommended)
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# Deploy it (the moment of truth)
cd terraform
terraform init
terraform plan
terraform apply
```

Set up GitHub Actions:
1. Go to your repo Settings → Secrets and variables → Actions
2. Add variable `AWS_ROLE_ARN` with the ARN from terraform output
3. Watch the magic happen

Now you can deploy:

```bash
# Edit your site
vi index.html

# Push changes (the easy part)
git add .
git commit -m "updated content"
git push

# Wait 2 minutes, grab coffee, it's live
```

## Daily workflow

### For Infrastructure Changes:
- **Edit Terraform files** - When you want to break things
- **Run terraform plan** - To see what you're about to break
- **Run terraform apply** - To actually break it (or fix it)
- **Git push** - To deploy the chaos

### For New Blog Posts:
- **Generate template**: `node js/new-post.js "Title" "slug" "tags" "excerpt"`
- **Edit content** - The actual writing part (ugh)
- **Update config** - Add entry to `js/posts.js`
- **Git push** - Live in 2 minutes (faster than medium.com)

### For Content Updates:
- **Edit files** - Change whatever needs changing
- **Git push** - Deploy it
- **Done** - Seriously, that's it

No FTP, no cPanel, no SSH tunnels, no "have you tried turning it off and on again?"

## What you get

- **Website loads in under 2 seconds globally**
- **99.9% uptime**
- **Real SSL certificate**
- **Security headers**
- **Automatic scaling**
- **Professional infrastructure**
- **Modern blog system**
- **Mobile responsive**

All for the cost of a fancy coffee per month.

## Domain setup

After deployment, point your domain to CloudFront:

```bash
terraform output cloudfront_domain_name
```
Add CNAME records at your DNS provider. It's easy when your domain is in Route53 (use Route53). Takes 10-30 minutes to propagate because DNS is still from the stone age.

```

## Costs

- **First year**: Free (AWS Free Tier covers everything)
- **After year 1**: $2-4/month depending on traffic
- **Break-even vs shared hosting**: Immediate
- **Break-even vs VPS**: Day one
- **Peace of mind**: Priceless (also free)

The cost monitoring will email you if something's wrong.

## Common problems

- **Terraform fails**: Check your AWS credentials with `aws sts get-caller-identity`
- **GitHub Actions failing**: Make sure you set the `AWS_ROLE_ARN` variable correctly
- **Domain not working**: DNS takes time. Be patient. Seriously.
- **Costs too high**: Something's misconfigured. The scripts should catch this.
- **New post script fails**: Install Node.js. It's 2024, you need it anyway.
- **CSS/JS not loading in posts**: Check that post files use `../css/` and `../js/` paths

## Why not Netlify/Vercel?

Good question. The goal was to play with AWS and Terraform, not to take the easy route. Plus, I now own the entire stack—no vendor lock-in (that's controversial), no surprise pricing changes (that too). Could I have deployed this in 5 minutes on Vercel? Sure. Would I have learned how CloudFront works? I guess not.

## What's next

Planning to add (when I get around to it):
- **Contact form using Lambda** - Because email is still a thing
- **Blog search functionality** - For when I write too many posts
- **Better monitoring with Grafana** - Pretty graphs make everything better
- **Maybe a staging environment** - Professional best practices and all that
- **RSS feed generation** - For the 3 people still using RSS readers
- **Post analytics** - To see which posts nobody reads

The infrastructure can handle way more than a static site, so a lot of room to grow.

## Blog Development Notes

### Theme System:
- **CSS variables** - For easy theme switching without losing my mind - I HATE CSS
- **localStorage persistence**
- **Works across all pages**

### Post Management:
- **Timestamp sorting** - For when I write multiple posts per day (ambitious, I know)
- **Automatic "Latest" badge** - Most recent post gets the spotlight
- **Tag filtering** - Click and filter, smooth as butter
- **Mobile-first design**

### File Organization:
- **Modular CSS** - Shared styles, blog-specific, article-specific
- **Reusable JavaScript** - Don't repeat yourself (DRY principle)
- **Clean separation** - Content and presentation know their place

---

This setup taught me more about cloud infrastructure than any tutorial or certification course. If you're trying to level up your DevOps skills, building something real like this beats studying theory every time. Plus, you get a website out of it.