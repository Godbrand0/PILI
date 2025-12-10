# Frontend Deployment Guide

This guide covers deploying the PILI frontend to various hosting platforms.

## Prerequisites

1. Ensure all environment variables are configured
2. Build the application locally first to verify everything works
3. Have your contract addresses ready

## Environment Variables

Create a `.env.production` file with the following variables:

```env
# Fhenix Network Configuration
NEXT_PUBLIC_FHENIX_RPC_URL=https://helix.fhenix.zone
NEXT_PUBLIC_FHENIX_CHAIN_ID=8008

# Contract Addresses (replace with deployed addresses)
NEXT_PUBLIC_IL_PROTECTION_HOOK_ADDRESS=0x...
NEXT_PUBLIC_FHE_MANAGER_ADDRESS=0x...

# WalletConnect Project ID
NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID=your_project_id_here

# Optional: Analytics
NEXT_PUBLIC_GA_ID=your_ga_id_here
```

## Build Process

1. Install dependencies:

```bash
npm install
```

2. Build the application:

```bash
npm run build
```

3. Test the build locally:

```bash
npm run start
```

## Deployment Platforms

### Vercel (Recommended)

1. Install Vercel CLI:

```bash
npm i -g vercel
```

2. Login to Vercel:

```bash
vercel login
```

3. Deploy:

```bash
vercel --prod
```

4. Configure environment variables in the Vercel dashboard

### Netlify

1. Build the application:

```bash
npm run build
```

2. Deploy the `out` directory to Netlify

3. Configure environment variables in Netlify dashboard

### AWS Amplify

1. Connect your GitHub repository to AWS Amplify

2. Configure build settings:

```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm install
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: .next
    files:
      - "**/*"
  cache:
    paths:
      - node_modules/**/*
```

3. Configure environment variables in Amplify console

### Cloudflare Pages

1. Build the application:

```bash
npm run build
```

2. Deploy the `.next` directory to Cloudflare Pages

3. Configure environment variables in Cloudflare dashboard

## Post-Deployment Checklist

- [ ] Verify the site loads correctly
- [ ] Test wallet connection
- [ ] Test contract interactions (if contracts are deployed)
- [ ] Check all navigation links work
- [ ] Verify responsive design on mobile devices
- [ ] Test error handling
- [ ] Check console for any errors

## Troubleshooting

### Common Issues

1. **Build fails with TypeScript errors**

   - Check for any type errors in the code
   - Ensure all dependencies are installed

2. **Wallet connection doesn't work**

   - Verify WalletConnect Project ID is set
   - Check if the correct network is configured

3. **Contract interactions fail**

   - Verify contract addresses are correct
   - Ensure RPC URL is accessible

4. **Styling issues**
   - Check if Tailwind CSS is properly configured
   - Verify CSS files are being loaded

### Debug Mode

To enable debug mode, add this to your environment variables:

```env
NEXT_PUBLIC_DEBUG=true
```

This will enable additional logging and error messages.

## Performance Optimization

1. **Image Optimization**

   - Use Next.js Image component for all images
   - Optimize image sizes and formats

2. **Code Splitting**

   - Next.js automatically splits code by pages
   - Use dynamic imports for large components

3. **Caching**

   - Configure proper cache headers
   - Use CDN for static assets

4. **Bundle Analysis**
   - Analyze bundle size with:
   ```bash
   npm run build
   npm run analyze
   ```

## Security Considerations

1. **Environment Variables**

   - Never expose private keys
   - Use only public environment variables

2. **Content Security Policy**

   - Configure CSP headers if needed
   - Allow only necessary domains

3. **HTTPS**
   - Always use HTTPS in production
   - Configure proper SSL certificates

## Monitoring

1. **Error Tracking**

   - Consider integrating Sentry or similar service
   - Monitor console errors

2. **Performance Monitoring**

   - Use tools like Lighthouse
   - Monitor Core Web Vitals

3. **Analytics**
   - Configure Google Analytics if needed
   - Track user interactions

## Maintenance

1. **Regular Updates**

   - Keep dependencies updated
   - Monitor for security vulnerabilities

2. **Backup**

   - Keep backups of your deployment configuration
   - Version control your environment variables

3. **Testing**
   - Regularly test all functionality
   - Run automated tests in CI/CD
