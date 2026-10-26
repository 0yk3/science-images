import { ScramjetHeaders } from "@/shared";
import { twhqResponse } from "@mercuryworkshop/proxy-transports";
import { ScramjetFetchParsed } from ".";
export declare function normalizeContentType(parsed: ScramjetFetchParsed, headers: ScramjetHeaders): void;
export declare function isRedirect(response: twhqResponse): boolean;
export declare function isDocument(parsed: ScramjetFetchParsed): boolean;
export declare function createReferrerString(clientUrl: URL, resource: URL, policy: string | null): string;
