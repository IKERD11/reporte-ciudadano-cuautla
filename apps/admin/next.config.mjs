import path from 'node:path';
const staticExport = process.env.STATIC_EXPORT === 'true';
const config={
  turbopack:{root:path.resolve(import.meta.dirname)},
  poweredByHeader:false,
  basePath:process.env.NEXT_PUBLIC_BASE_PATH || '',
  ...(staticExport ? {output:'export',trailingSlash:true} : {
    async headers(){return [{source:'/:path*',headers:[{key:'Referrer-Policy',value:'strict-origin-when-cross-origin'},{key:'X-Content-Type-Options',value:'nosniff'},{key:'X-Frame-Options',value:'DENY'}]}]}
  }),
};
export default config;
