/** @jsx h */
// import blog, { ga, redirects } from 'https://deno.land/x/blog@0.5.0/blog.tsx'
// import blog from '../deno_blog/blog.tsx'
import blog, {
  h,
} from 'https://raw.githubusercontent.com/kyeotic/deno_blog/custom-url/blog.tsx'
import { theme } from './config/highlight.ts'

blog({
  title: 'T++',
  author: 'Tim Kye',
  avatar: './images/avatar.png',
  avatarClass: 'full',
  favicon: './images/favicon.ico',
  links: [
    { title: 'GitHub', url: 'https://github.com/kyeotic' },
    { title: 'Email', url: 'mailto:tim@kye.dev' },
  ],
  theme: 'dark',
  style: theme,
  footer: (
    <footer class="mt-20 pb-16 lt-sm:pb-8 lt-sm:mt-16">
      <a href="/" title="T++">
        T++ © {new Date().getFullYear()}
      </a>
    </footer>
  ),
})
