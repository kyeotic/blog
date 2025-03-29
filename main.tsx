/** @jsx h */
// https://github.com/denoland/deno_blog
// import blog, { h, ga, redirects } from 'https://deno.land/x/blog@0.7.0/blog.tsx'
// Using fork to bump deno-gfm dep
// import blog, {
//   h,
//   ga,
//   redirects,
// } from 'https://raw.githubusercontent.com/denoland/deno_blog/main/blog.tsx'
import blog, {
  h,
  ga,
  redirects,
} from 'https://raw.githubusercontent.com/kyeotic/deno_blog/main/blog.tsx'
// import blog, { h, ga, redirects } from '../deno_blog/blog.tsx'
import { theme } from './config/highlight.ts'

blog({
  title: 'T++',
  author: 'Tim Kye',
  avatar: './posts/images/avatar.png',
  avatarClass: 'full',
  favicon: './posts/images/favicon.ico',
  links: [
    { title: 'GitHub', url: 'https://github.com/kyeotic' },
    { title: 'Email', url: 'mailto:tim@kye.dev' },
  ],
  theme: 'dark',
  style: theme,
  // header: <header>Your custom header</header>,
  footer: (
    <footer class="mt-20 pb-16 lt-sm:pb-8 lt-sm:mt-16">
      <a href="/" title="T++">
        T++ © {new Date().getFullYear()}
      </a>
    </footer>
  ),
})
