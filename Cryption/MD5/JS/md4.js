/* 
    * A JavaScript implementation of the RSA Data Security, Inc. MD4 Message 
    * Digest Algorithm, as defined in RFC 1320. 
    * Version 2.1 Copyright (C) Jerrad Pierce, Paul Johnston 1999 - 2002. 
    * Other contributors: Greg Holt, Andrew Kepert, Ydnar, Lostinet 
    * Distributed under the BSD License 
    * See http://pajhome.org.uk/crypt/md5 for more info. 
    */  
    
/* 
    * Configurable variables. You may need to tweak these to be compatible with 
    * the server-side, but the defaults work in most cases. 
    */  
var hexcase = 0;  /* hex output format. 0 - lowercase; 1 - uppercase        */  
var b64pad  = ""; /* base-64 pad character. "=" for strict RFC compliance   */  
var chrsz   = 16;  /* bits per input character. 8 - ASCII; 16 - Unicode      */  
    
/* 
    * These are the functions you'll usually want to call 
    */  
function hex_md4(s){ return binl2hex(core_md4(str2binl(s), s.length * chrsz));}  
function b64_md4(s){ return binl2b64(core_md4(str2binl(s), s.length * chrsz));}  
function str_md4(s){ return binl2str(core_md4(str2binl(s), s.length * chrsz));}  
function hex_hmac_md4(key, data) { return binl2hex(core_hmac_md4(key, data)); }  
function b64_hmac_md4(key, data) { return binl2b64(core_hmac_md4(key, data)); }  
function str_hmac_md4(key, data) { return binl2str(core_hmac_md4(key, data)); }  
    
/*  
    * Perform a simple self-test to see if the VM is working  
    */  
function md4_vm_test()  
{  
    return hex_md4("abc") == "a448017aaf21d8525fc10ae87aa6729d";  
}  
    
/* 
    * Calculate the MD4 of an array of little-endian words, and a bit length 
    */  
function core_md4(x, len)  
{  
    /* append padding */  
    x[len >> 5] |= 0x80 << (len % 32);  
    x[(((len + 64) >>> 9) << 4) + 14] = len;  
    
    var a =  1732584193;  
    var b = -271733879;  
    var c = -1732584194;  
    var d =  271733878;  
    
    for(var i = 0; i < x.length; i += 16)  
    {  
    var olda = a;  
    var oldb = b;  
    var oldc = c;  
    var oldd = d;  
    
    a = md4_ff(a, b, c, d, x[i+ 0], 3 );  
    d = md4_ff(d, a, b, c, x[i+ 1], 7 );  
    c = md4_ff(c, d, a, b, x[i+ 2], 11);  
    b = md4_ff(b, c, d, a, x[i+ 3], 19);  
    a = md4_ff(a, b, c, d, x[i+ 4], 3 );  
    d = md4_ff(d, a, b, c, x[i+ 5], 7 );  
    c = md4_ff(c, d, a, b, x[i+ 6], 11);  
    b = md4_ff(b, c, d, a, x[i+ 7], 19);  
    a = md4_ff(a, b, c, d, x[i+ 8], 3 );  
    d = md4_ff(d, a, b, c, x[i+ 9], 7 );  
    c = md4_ff(c, d, a, b, x[i+10], 11);  
    b = md4_ff(b, c, d, a, x[i+11], 19);  
    a = md4_ff(a, b, c, d, x[i+12], 3 );  
    d = md4_ff(d, a, b, c, x[i+13], 7 );  
    c = md4_ff(c, d, a, b, x[i+14], 11);  
    b = md4_ff(b, c, d, a, x[i+15], 19);  
    
    a = md4_gg(a, b, c, d, x[i+ 0], 3 );  
    d = md4_gg(d, a, b, c, x[i+ 4], 5 );  
    c = md4_gg(c, d, a, b, x[i+ 8], 9 );  
    b = md4_gg(b, c, d, a, x[i+12], 13);  
    a = md4_gg(a, b, c, d, x[i+ 1], 3 );  
    d = md4_gg(d, a, b, c, x[i+ 5], 5 );  
    c = md4_gg(c, d, a, b, x[i+ 9], 9 );  
    b = md4_gg(b, c, d, a, x[i+13], 13);  
    a = md4_gg(a, b, c, d, x[i+ 2], 3 );  
    d = md4_gg(d, a, b, c, x[i+ 6], 5 );  
    c = md4_gg(c, d, a, b, x[i+10], 9 );  
    b = md4_gg(b, c, d, a, x[i+14], 13);  
    a = md4_gg(a, b, c, d, x[i+ 3], 3 );  
    d = md4_gg(d, a, b, c, x[i+ 7], 5 );  
    c = md4_gg(c, d, a, b, x[i+11], 9 );  
    b = md4_gg(b, c, d, a, x[i+15], 13);  
    
    a = md4_hh(a, b, c, d, x[i+ 0], 3 );  
    d = md4_hh(d, a, b, c, x[i+ 8], 9 );  
    c = md4_hh(c, d, a, b, x[i+ 4], 11);  
    b = md4_hh(b, c, d, a, x[i+12], 15);  
    a = md4_hh(a, b, c, d, x[i+ 2], 3 );  
    d = md4_hh(d, a, b, c, x[i+10], 9 );  
    c = md4_hh(c, d, a, b, x[i+ 6], 11);  
    b = md4_hh(b, c, d, a, x[i+14], 15);  
    a = md4_hh(a, b, c, d, x[i+ 1], 3 );  
    d = md4_hh(d, a, b, c, x[i+ 9], 9 );  
    c = md4_hh(c, d, a, b, x[i+ 5], 11);  
    b = md4_hh(b, c, d, a, x[i+13], 15);  
    a = md4_hh(a, b, c, d, x[i+ 3], 3 );  
    d = md4_hh(d, a, b, c, x[i+11], 9 );  
    c = md4_hh(c, d, a, b, x[i+ 7], 11);  
    b = md4_hh(b, c, d, a, x[i+15], 15);  
    
    a = safe_add(a, olda);  
    b = safe_add(b, oldb);  
    c = safe_add(c, oldc);  
    d = safe_add(d, oldd);  
    
    }  
    return Array(a, b, c, d);  
    
}  
    
/* 
    * These functions implement the basic operation for each round of the 
    * algorithm. 
    */  
function md4_cmn(q, a, b, x, s, t)  
{  
    return safe_add(rol(safe_add(safe_add(a, q), safe_add(x, t)), s), b);  
}  
function md4_ff(a, b, c, d, x, s)  
{  
    return md4_cmn((b & c) | ((~b) & d), a, 0, x, s, 0);  
}  
function md4_gg(a, b, c, d, x, s)  
{  
    return md4_cmn((b & c) | (b & d) | (c & d), a, 0, x, s, 1518500249);  
}  
function md4_hh(a, b, c, d, x, s)  
{  
    return md4_cmn(b ^ c ^ d, a, 0, x, s, 1859775393);  
}  
    
/* 
    * Calculate the HMAC-MD4, of a key and some data 
    */  
function core_hmac_md4(key, data)  
{  
    var bkey = str2binl(key);  
    if(bkey.length > 16) bkey = core_md4(bkey, key.length * chrsz);  
    
    var ipad = Array(16), opad = Array(16);  
    for(var i = 0; i < 16; i++)   
    {  
    ipad[i] = bkey[i] ^ 0x36363636;  
    opad[i] = bkey[i] ^ 0x5C5C5C5C;  
    }  
    
    var hash = core_md4(ipad.concat(str2binl(data)), 512 + data.length * chrsz);  
    return core_md4(opad.concat(hash), 512 + 128);  
}  
    
/* 
    * Add integers, wrapping at 2^32. This uses 16-bit operations internally 
    * to work around bugs in some JS interpreters. 
    */  
function safe_add(x, y)  
{  
    var lsw = (x & 0xFFFF) + (y & 0xFFFF);  
    var msw = (x >> 16) + (y >> 16) + (lsw >> 16);  
    return (msw << 16) | (lsw & 0xFFFF);  
}  
    
/* 
    * Bitwise rotate a 32-bit number to the left. 
    */  
function rol(num, cnt)  
{  
    return (num << cnt) | (num >>> (32 - cnt));  
}  
    
/* 
    * Convert a string to an array of little-endian words 
    * If chrsz is ASCII, characters >255 have their hi-byte silently ignored. 
    */  
function str2binl(str)  
{  
    var bin = Array();  
    var mask = (1 << chrsz) - 1;  
    for(var i = 0; i < str.length * chrsz; i += chrsz)  
    bin[i>>5] |= (str.charCodeAt(i / chrsz) & mask) << (i%32);  
    return bin;  
}  
    
/* 
    * Convert an array of little-endian words to a string 
    */  
function binl2str(bin)  
{  
    var str = "";  
    var mask = (1 << chrsz) - 1;  
    for(var i = 0; i < bin.length * 32; i += chrsz)  
    str += String.fromCharCode((bin[i>>5] >>> (i % 32)) & mask);  
    return str;  
}  
    
/* 
    * Convert an array of little-endian words to a hex string. 
    */  
function binl2hex(binarray)  
{  
    var hex_tab = hexcase ? "0123456789ABCDEF" : "0123456789abcdef";  
    var str = "";  
    for(var i = 0; i < binarray.length * 4; i++)  
    {  
    str += hex_tab.charAt((binarray[i>>2] >> ((i%4)*8+4)) & 0xF) +  
            hex_tab.charAt((binarray[i>>2] >> ((i%4)*8  )) & 0xF);  
    }  
    return str;  
}  
    
/* 
    * Convert an array of little-endian words to a base-64 string 
    */  
function binl2b64(binarray)  
{  
    var tab = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";  
    var str = "";  
    for(var i = 0; i < binarray.length * 4; i += 3)  
    {  
    var triplet = (((binarray[i   >> 2] >> 8 * ( i   %4)) & 0xFF) << 16)  
                | (((binarray[i+1 >> 2] >> 8 * ((i+1)%4)) & 0xFF) << 8 )  
                |  ((binarray[i+2 >> 2] >> 8 * ((i+2)%4)) & 0xFF);  
    for(var j = 0; j < 4; j++)  
    {  
        if(i * 8 + j * 6 > binarray.length * 32) str += b64pad;  
        else str += tab.charAt((triplet >> 6*(3-j)) & 0x3F);  
    }  
    }  
    return str;  
}  