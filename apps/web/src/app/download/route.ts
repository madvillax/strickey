import { download } from "@/lib/site";

// Keep old /download links working; all landing-page buttons use the file directly.
export function GET() {
  return new Response(null, { status: 307, headers: { Location: download } });
}
