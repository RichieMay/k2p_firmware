#!/usr/bin/lua
LuaQ    @ccgame_util.lua                 A@   E     \    ÁÀ   Å    Ü AA FAA\  ÁÁ   A B@ B U ÁÂ  AC  ËDAD D Á ÜÀ Â ÚC    Â   d                  GÄ EÄ \D dD  G d          GD dÄ    G d    GÄ dD    G d               GD dÄ     G d     GÄ dD G d GD dÄ G d GÄ dD G d    GD dÄ G d GÄ dD    G	 d    GD	 dÄ    G	 d   GÄ	 dD G
 d            GD
 dÄ         G
 d   GÄ
 dD      G d    GD   .      require 	   nixio.fs 
   luci.json    luci.model.uci    posix    cursor    /tmp/ccgame    ccgame_state    /ccgame_ipset    /ccgame.log    ipset_ccgame 
   rt_ccgame    /tmp/ipset_conn_reset    ipset_conn_reset 	      1    get    ccgame    debug    ccgame_util_init    log_to_file    dbg    logger 	   cfg_read 
   cfg_write    state_init    state_read    state_write    cc_func_exec_c    cc_func_exec    cc_func_execl    trim    cc_ping_vpn_list    cc_func_ccserver_request    cc_func_get_vpn_server_ip    cc_func_get_vpn_server_list    vpn_get_server 
   vpn_start 	   vpn_stop    vpn_restart 
   vpn_state    speedup_info_apply    speedup_reset_conntrack_start    speedup_reset_conntrack_end    speedup_info_delete    speedup_ip_get           "     "       @ A@    ÅÀ  @    A D   @  @@ A AÀ   U @     À@ A A    U @ @ B D  À          openlog    ccgame    np 	   LOG_USER    access    os    execute    mkdir     echo 'ccgame start' >     io    open    a     "                                                                                                            "             px    fs 	   dir_work    g_debug 	   file_log 	   fd_debug     %   ,     	    @ A       ËÀ@ E FAÁ \ Á À  UÜ@  	      seek    end 	      write    os    date    %x %X     :     
        &   &   &   (   (   )   +   +   +   +   +   +   +   +   +   +   ,         fileid           msg        
   file_size               .   ;               Z   ÀÁ    A@@   A  @     Ä  Ú   À Å   @ Ü@        '    encode    log_to_file        /   /   /   0   2   2   3   3   3   3   3   3   3   3   5   7   7   7   8   8   8   8   ;         obj           is_obj           str             g_debug    json 	   fd_debug     =   @    	   E      \@ D   F@À   À   \@        dbg    syslog 	       	   >   >   >   ?   ?   ?   ?   ?   @         msg              px     C   F    	     @  À   A     [A   AA  ^         get            D   D   D   D   D   D   D   D   D   E   E   E   E   F         package           section           option           default           val 	            cursor     I   L    
     @  À   @A   A@  A        set    commit        J   J   J   J   J   J   J   K   K   K   K   L         package           section           option           value              cursor     N       ¦   A    A@Ä   D ÕA A   Á  AÁA  A   ÕA A A 
A AÁA A B @  ÁA A    ÁA A Â À  ÁA A    AC A A C AÁC A  A    ÁC A B Å CB Ü A  C AZ   @   À Ú   @ A       ÁA @    @A Ä ËÁÁA  Á Ü  Ä ËÁÄA  ä       ÜA£  À ÁD A ¤B      A ÁC @  A ÁC @  ÁB A  ÁC @  À A  ÁC @ Â ÀA  ÁC @  À A  C A     	
      access    /    os    execute    touch     set_confdir    get    ccgame    gameid    rtt    lose    jitter    delete    commit    set 	   tostring 	   tonumber    index    foreach    history    0        l   q    	   E   @@ \     ÀD  KÀ ÁÀ  A AA  A Å  B@ Ü ÌÁ \@       	   tonumber    index    set    ccgame    .name 	   tostring 	          m   m   m   m   m   m   n   n   n   n   n   o   o   o   o   o   o   n   q         s              index    cursor     s   z    	   E   @@ \    @@ @D  KÀÀ Á  AA \@ ÀD  KÁ Á  AA AA  Á Å  B@ Ü ÌÀ \@       	   tonumber    index 	      delete    ccgame    .name    set 	   tostring        t   t   t   t   t   t   t   u   u   u   u   u   u   w   w   w   w   w   x   x   x   x   x   x   w   z         s              maxnum    cursor ¦   P   R   R   R   R   R   R   R   R   R   S   S   S   S   S   S   S   S   T   T   T   T   T   V   V   V   V   W   W   W   W   W   W   W   X   X   X   X   X   X   X   Y   Y   Y   Y   Y   Y   Y   Z   Z   Z   Z   Z   Z   Z   [   [   [   [   [   \   \   \   \   ^   ^   ^   ^   ^   ^   _   _   `   `   `   `   `   `   `   `   `   b   b   b   b   d   d   d   d   d   d   d   d   e   i   i   i   i   i   i   i   j   j   j   j   j   j   j   j   l   l   l   l   q   q   q   l   q   q   s   s   s   s   z   z   z   s   }   }   }   }   }   }   ~   ~   ~   ~   ~   ~   ~                                                                                       cfg     ¥      gameid     ¥      rtt     ¥      lose     ¥      jitter     ¥      maxnum    ¥      index m   u         fs 	   dir_work    filename_state    state_cursor    cursor               D   K À Ä  A  @  ] ^           get    ccgame                                      option              state_cursor    filename_state                   @ AA    À @    @ @        set    ccgame    commit                                                  option           value              state_cursor    filename_state                E   F@À    \ À Á  Ë Á Ü@ Æ@A   A ÜÚ@    ÁÀ Þ          io    popen    read    *all    close    match    (.+)%c$                                                                        string           res          tmpstr                          E   F@À    \ À Á  Ë Á Ü@           io    popen    read    *a    close                                               command     
      pp    
      data    
              ª        E   F@À    \   Ê   ÁÀ     A  À AAÉ @ýÁ A Þ          io    popen        read  	      close                           £   £   £   ¤   ¤   ¤   ¥   ¥   ¥   ¥   §   §   ©   ª         command           pp          line          data               ¬   ®        K @ Á@    ]  ^           gsub    ^%s*(.-)%s*$    %1        ­   ­   ­   ­   ­   ®         str                °   ë     |   J      Á@  @ @  @       À    ÀÅÁ  ÆÁ  AB ÜÁÚ  @ B  EÂ  FÁ Á \ÀÚ  @ Â   Ã Ú  @  ÀA UB À   ÀÊ  Ã  B@ Ã C  @ ÉÃ@EÃ  FÁ ÁC \ÉBEÃ  FÁ ÁÃ \ÉBEÃ  FÂ Á \ZC  @ ÉÃÃ  BÀ  @ ÅÃ  ÆÃÄ  LE Ü Ä  B@D EÄ  FÄÄÌE\ Ä  B	ÀE ÅÄ  ÆÄÄ	 A E	Ü ÉÂÉÃ FÀ  C¡  @å   À   @^          dbg    start to ping vpn_list    ipairs    string    match    (%d+.%d+.%d+.%d+):(%d+)    (%d+.%d+.%d+.%d+) 	       ping -c 2     cc_func_exec    find    ttl 	'  
   ttl=(%d+)    lose    (%d+)%%%s+packet     round%-trip    rtt    =    sub 	      /    ip    table    insert     |   ±   ³   ³   ³   ´   ´   µ   µ   ¸   ¸   ¸   ¸   ¹   ¹   ¹   ¹   ¹   »   »   »   »   ¼   ¼   ¼   ¼   ¼   ¼   ½   ½   ¾   ¾   À   Å   Å   Å   Å   Æ   Æ   Æ   Ç   Ç   Ç   É   É   Ê   Î   Î   Î   Î   Î   Ï   Ï   Ð   Ð   Ò   Ò   Ò   Ò   Ò   Ò   Õ   Õ   Õ   Õ   Õ   Õ   ×   ×   ×   ×   ×   Ø   Ø   Ù   Ù   Û   Û   Û   Û   Û   Û   Ü   Ü   Ü   Ü   Ü   Ü   Ý   Ý   Ý   Ý   Ý   Þ   Þ   Þ   Þ   Þ   Þ   ß   ß   ß   ß   ß   à   à   à   à   à   à   à   ã   ä   ä   ä   ä   ä   ¸   æ   é   é   é   é   ê   ë         iplist     {      vpnlist_qos    {      (for generator)    v      (for state)    v      (for control)    v      i    t      v    t      myip    t      myport    t      cmd '   t      ps *   t      ping_state -   t   	   is_match 2   t      st G   t      eb Q   n      abc_sub W   n      st_1 \   n   
   abc_sub_1 b   n      st_2 g   n           í      S   Á   
  FAÀ 	AFÀ 	AFÁÀ 	AFÁ 	A	EÁ FÁ\ 	A	 EA FÂÁ Ä  ÆÃ  Ü  \ A Á  ÕA Á Å  Á  @ ÚA  @ B  B A UB ÀD   @B @ À Ú  @ Å@ B  Â d       Â    Z   ÂÅB  @   ÂÅW E@ ÂÅ  ÆÂ     '   http://games.nubesi.com/manager/ccgame    uid    devicetype    version 	   usertype    cmdid    time    os    data    string    format M   curl -H "Content-type: application/json" -X POST --data '%s' %s  2>/dev/null    encode    dbg    cc_func_ccserver_request cmd     pcall    cc_func_exec 	Õÿÿ'   cc_func_ccserver_request curl success: 	   	       trim        code 	Õÿÿ                    @ D               decode                              json 	   curl_ret S   î   ï   ñ   ñ   ò   ò   ó   ó   ô   ô   õ   ö   ö   ö   ö   ÷   ù   ù   ú   û   û   û   û   û   ù   ü   ü   ü   ü   ü   þ   þ   þ   þ   ÿ   ÿ   ÿ   ÿ                                     	  	  	  	  
  
                                                
      cmdid     R      cfg     R      data     R      cc_serverurl    R      cmdhead    R      cmd    R   	   ret_curl "   R   	   curl_ret "   R      ret A   R      curl_ret_struct A   R         json       +    	"   À  Æ @ À Æ@@ À@ ÅÀ   @   ÜÀ W@ÁÀE Á À \A C^    FABZA   E  \A C^ FAB^         gameid 	   regionid    info    cc_func_ccserver_request 	   	       dbg ;   cc_func_get_vpn_server_ip cc_func_ccserver_request return:    . 	   serverip B   cc_func_get_vpn_server_ip cc_func_ccserver_request data is empty.     "                               !  !  !  !  !  !  "  "  %  %  %  %  %  &  &  &  '  '  *  *  +        cfg     !      vpnlist_qos     !      data    !      code    !   	   ret_data    !           -  >       J@  @@ I   ÁÀ     @ À W AÀA A  ÁÁ UÁA   Ú    ÂA   A AA A   Â   
      passwd 	   password    cc_func_ccserver_request 	   	       dbg =   cc_func_get_vpn_server_list cc_func_ccserver_request return:    .    iplist D   cc_func_get_vpn_server_list cc_func_ccserver_request data is empty.        .  /  /  2  2  2  2  2  3  3  4  4  4  4  4  4  5  5  8  8  8  8  8  9  9  9  :  :  =  =  >        cfg           data          code       	   ret_data               @  Y   	8   E      \ Z@  @     @  @À  Á  @  @ Ã Þ  Å    Ü Ú@  @   A @  A  @ C^ E Á Ä  ÆÂ  Ü Á\A E A À Á\A E Á Ä  ÆÂ Ü Á\A @ ^  
      cc_func_get_vpn_server_list    string    split    ,    cc_ping_vpn_list    cc_func_get_vpn_server_ip    dbg    vpn_get_server:    encode    vpn_get_server: serverip=     8   A  A  A  B  B  C  C  F  F  F  F  F  G  G  H  H  K  K  K  L  L  M  M  P  P  P  P  Q  Q  R  R  U  U  U  U  U  U  U  U  V  V  V  V  V  W  W  W  W  W  W  W  W  X  X  X  Y        cfg     7      vpns    7      vpnlist    7      vpnlist_qos    7   	   serverip    7         json     [  g   	C   Å   A  Ü@ Ä   ËÀAÁ   ÁA Ü@Ä   ËÀAÁ   Á Â Ü@ Ä   ËÀAÁ   Á B Ü@ Ä   ËÀAÁ   Á Â Ü@ Ä   ËÀAÁ   Á    Ü@ Ä   ËÀAÁ   ÁA   Ü@ Ä   ËÀAÁ   Á   Ü@ Ä   ËÀAÁ   ÁÁ B Ü@ Ä   Ë ÄAÁ  Ü@Å@ ÆÄÁ Ü@         dbg 
   vpn_start    set    network    vpn_cc 
   interface    pppd_options    refuse-eap    peerdns    0    proto    l2tp 	   username 	   password    server    defaultroute    commit    os    execute    ifup vpn_cc     C   \  \  \  ]  ]  ]  ]  ]  ]  ^  ^  ^  ^  ^  ^  ^  _  _  _  _  _  _  _  `  `  `  `  `  `  `  a  a  a  a  a  a  a  b  b  b  b  b  b  b  c  c  c  c  c  c  c  d  d  d  d  d  d  d  e  e  e  e  f  f  f  f  g     	   username     B   	   password     B   	   serverip     B         cursor     i  n          A@  @   À@ A  @    @A  ÁÀ @     B  @  	      dbg 	   vpn_stop    os    execute    ifdown vpn_cc >/dev/null 2>&1    delete    network    vpn_cc    commit        j  j  j  k  k  k  k  l  l  l  l  l  m  m  m  m  n            cursor     p  u          A@  @   À@ A  @    @A A @   À@ AÀ @         dbg    vpn_restart    os    execute    ifdown vpn_cc >/dev/null 2>&1    sleep 	      ifup vpn_cc        q  q  q  r  r  r  r  s  s  s  s  t  t  t  t  u            px     w  ¥     j   
   J     Å   A  Ü   @@ÀÀ@E FBÁ Á \ @  À @ÀÁKÂBÁ \IÀII@ @Ã@KÂBÁ \ÂII@ 	@Ä KÂBÁÂ \I@I IÀII@@ Æ KÂBÁ \I@I IÀII@ÀÇ@KÂBÁ \ÂII@ÀÈ KÂBÁ	 \ÂII@!  Àî   Â   ÀAÂ    É   @AÉ   	ÀÀÂ 	 É 	 AÉ 	  @  AÂ       *      cc_func_execl !   ifconfig l2tp-vpn_cc 2>/dev/null    ipairs 	      string    find    l2tp%-vpn_cc 	      ip    ptp    mask    match Q   inet addr:(%d+.%d+.%d+.%d+)%s+P%-t%-P:(%d+.%d+.%d+.%d+)%s+Mask:(%d+.%d+.%d+.%d+) 	      mtu    metric    MTU:(%w+)%s+Metric:(%w+) 	      rx_packets 
   rx_errors    rx_dropped    rx_overruns 	   rx_frame L   packets:(%d+)%s+errors:(%d+)%s+dropped:(%d+)%s+overruns:(%d+)%s+frame:(%d+) 	      tx_packets 
   tx_errors    tx_dropped    tx_overruns    tx_carrier N   packets:(%d+)%s+errors:(%d+)%s+dropped:(%d+)%s+overruns:(%d+)%s+carrier:(%d+) 	      collisions    txqueuelen $   collisions:(%d+)%s+txqueuelen:(%d+) 	   	   rx_bytes 	   tx_bytes    bytes:(%d+).+:(%d+)    status    rx    tx     j   x  y  z  {  {  {  }  }  }  }  ~  ~                                                                                                                                  }                                                ¢  ¢  ¢  ¢  ¤  ¤  ¥  	   	   vpnstate    i      res    i   	   is_match    i      data    i      (for generator) 	   N      (for state) 	   N      (for control) 	   N      i 
   L      line 
   L           §  â   ©      @@Á    Õ @ À   AÄ   A @  @ Á Þ  Ê   Á @  ÀE FBÂ Á \Z    ÉÀÂ!  @ý @ÀKBCÁ  AÃ Á ÕÂ\B!  @ýADA  AÁ  U E  \ ZA  ÀE  FAÀA Ä  \A E  FAÀÁ Ä  \A E  FAÀA Ä  Á\A E  FAÀ  Ä  Á\A E  Ä Á\  E  \ ZA   E  FAÀÁ Á  AB  \A E  FAÀÁ Á Á\A E  FAÀÁ Á Á\A E A ÄÁ\  E  \ ZA  ÀE  FAÀ ÄÂ \A E  FAÀ	 ÄB	 \A E  FAÀ	 À Â	 DA\A E 
 \  E  \ ZA  ÀE  FAÀA
 Ä 
 DA\A AÁ
 ^   ,      os    execute    rm -rf     io    open    a 	ÿÿÿÿ   ipairs    string    match    %d+.%d+.%d+.%d+    pairs    write    add          
    close    cc_func_execl    ipset -L -t | grep     next    ipset create  A    hash:ip family inet hashsize 8192 maxelem 65536 >/dev/null 2>&1    ipset flush      2>/dev/null    ipset restore -f  !   iptables -w -t mangle -S | grep  /   iptables -w -t mangle -A PREROUTING -i br-lan  /   -m conntrack --ctstate NEW -m set --match-set      dst -j MARK --set-mark  F   -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark 3   iptables -w -t mangle -A POSTROUTING -m conntrack  &   --ctstate NEW -j CONNMARK --save-mark $   cat /etc/iproute2/rt_tables | grep     echo '102     ' >> /etc/iproute2/rt_tables    ip route flush table      >/dev/null 2>&1    ip route add default via      dev l2tp-vpn_cc table     ip rule | grep fwmark    ip rule add from all fwmark  	    lookup  	        ©   ©  ©  ©  ©  ©  ©  ª  ª  ª  ª  ª  «  «  ¬  ¬  ¯  °  °  °  °  ±  ±  ±  ±  ±  ²  ²  ³  °  ´  ¶  ¶  ¶  ¶  ·  ·  ·  ·  ·  ·  ·  ·  ¶  ·  ¹  ¹  »  »  »  »  »  ¼  ¼  ¼  ¼  ¼  ½  ½  ½  ½  ¾  ¾  ½  ¾  À  À  À  À  À  À  À  Â  Â  Â  Â  Â  Â  Ã  Ã  Ã  Ã  Ã  Ã  Æ  Æ  Æ  Æ  Æ  Æ  Ç  Ç  Ç  Ç  Ç  È  È  È  É  É  Ê  Ê  Ê  È  Ë  Ë  Ë  Ì  Ì  Ë  Í  Í  Í  Î  Î  Í  Ò  Ò  Ò  Ò  Ò  Ò  Ó  Ó  Ó  Ó  Ó  Ô  Ô  Ô  Ô  Ô  Ô  Ô  Ô  Ö  Ö  Ö  Ö  Ö  Ö  Ö  Ø  Ø  Ø  Ø  Ù  Ù  Ù  Ø  Ü  Ü  Ü  Ü  Ý  Ý  Ý  Ý  Ý  Þ  Þ  Þ  Þ  Þ  Þ  Þ  Þ  á  á  â        speedup_info     ¨      gateway_ip     ¨      file    ¨      speedup_ip    ¨      (for generator)          (for state)          (for control)          i          value          ip          (for generator) !   ,      (for state) !   ,      (for control) !   ,      ip "   *      __ "   *   	   ret_data 3   ¨         file_ipset    ipset_name    fwmark    rttable_name     ä      u      A@  @ 
   E  À  Ä     \ @ À   ÀËAAÂ ÜÁÚ       	 ¡  @ý  @BÁ  Õ @ À  CÄ  A @   Å    Ü@ ÁÀ Þ  Å     Ü @BD Ä Ã @  ÀD Bá  ÀüËEÜ@ Å  Á D AÜ  @ A  À ABAA  Á UÁA  ABAÁ  Á UÁA  ABAA  UA  ABA  UA   A  U À   @ A  À ABAÁ  Ä B UA   "      dbg    speedup_reset_conntrack    cc_func_execl    grep 'ipv4 * 2 * tcp .*mark=    ' /proc/net/nf_conntrack    ipairs    match $   dst=([0-9.]+) sport=(%d+) dport=%d+    os    execute    rm -rf     io    open    a     open ipset_connreset_file error 	ÿÿÿÿ   pairs    write    add          ,    
    close    ipset -L -t | grep     next    ipset create  F    hash:ip,port family inet hashsize 8192 maxelem 65536 >/dev/null 2>&1    ipset flush      2>/dev/null    ipset restore -f     iptables -w -S | grep  )   iptables -w -I FORWARD -i br-lan -p tcp     -m set --match-set  +    dst,src -j REJECT --reject-with tcp-reset     u   å  å  å  æ  ç  ç  ç  è  è  ç  ê  ê  ê  ê  ë  ë  ë  ì  ì  ì  ì  í  ê  î  ñ  ñ  ñ  ñ  ñ  ñ  ò  ò  ò  ò  ò  ó  ó  ô  ô  ô  õ  õ  ÷  ÷  ÷  ÷  ø  ø  ø  ø  ø  ø  ø  ø  ø  ø  ÷  ø  ú  ú  ü  ü  ü  ü  ü  ý  ý  ý  ý  ý  þ  þ  þ  þ  ÿ  ÿ  þ  ÿ                                                              	  	  	  
  
      	       	   ip_sport    t      data 
   t      (for generator)          (for state)          (for control)          i          line          dip          sport          file #   t      (for generator) -   :      (for state) -   :      (for control) -   :      ip .   8      sport .   8   	   ret_data A   t         fwmark    ipset_connreset_file    ipset_connreset_name                 @@ A  À  Ä    U  @    @@ A@    Á UÀ @    @@ AÀ    Á UÀ @   A@ @   
      os    execute )   iptables -w -D FORWARD -i br-lan -p tcp     -m set --match-set  +    dst,src -j REJECT --reject-with tcp-reset    ipset flush      2>/dev/null    ipset destroy     dbg    speedup_reset_conntrack end                                                                      ipset_connreset_name       3    >      @@ A     ÁÀ  UÀ @    @@ A     Á@ UÀ @    @@ A    Á@ UÀ @ À A  @ U  A    Á ` E  FAÀÁ Æ  D B \A _@ýE   F@À  Ä  A  \@ EÀ \@ E   F@À   Á@ À \@ E   F@À  ÁÀ À \@         os    execute ,   iptables -w -t mangle -S PREROUTING | grep  A    | sed -e 's/^-A/iptables -w -t mangle -D/' | sh >/dev/null 2>&1    ipset flush      2>/dev/null    ipset destroy     cc_func_execl    ip rule | grep fwmark |  /   awk -F'fwmark' '{print $2}' | awk '{print $1}' 	      ip rule del from all fwmark  	    lookup      >/dev/null 2>&1    ip route flush table     speedup_reset_conntrack_start A   iptables -w -t mangle -D POSTROUTING -m conntrack --ctstate NEW  )   -j CONNMARK --save-mark > /dev/null 2>&1 <   iptables -w -t mangle -D PREROUTING -i br-lan -m conntrack  I   --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark >/dev/null 2>&1     >                                                    #  #  $  $  #  %  %  %  %  &  &  &  &  &  '  '  '  &  %  )  )  )  )  )  )  )  ,  ,  /  /  /  0  0  /  1  1  1  2  2  1  3        fwmarks    =      (for index)    (      (for limit)    (      (for step)    (      i    '         ipset_name    rttable_name     5  B    
   
   E   @  Á     \ À  À   ÀËAAB ÜÁÚ       	 ¡  @ý          cc_func_execl 7   grep 'ipv4 * 2 * tcp .*ASSURED' /proc/net/nf_conntrack     | grep mark=    ipairs    match $   dst=([0-9.]+) sport=%d+ dport=(%d+)        6  7  7  8  8  8  7  :  :  :  :  ;  ;  ;  <  <  <  <  =  :  >  A  B  	      speedup_ipport          data          (for generator) 
         (for state) 
         (for control) 
         i          line          dip          dport             fwmark                                              	   	   
                                                                           "   "   "   "   "   "   "      #   #   ,   %   ;   ;   ;   ;   .   @   @   =   F   F   C   L   L   I                     N                                       ª      ®   ¬   ë   °       í   +    >  -  Y  Y  @  g  g  [  n  n  i  u  u  p  ¥  w  â  â  â  â  â  §          ä        3  3  3    B  B  5  B        fs          json          uci 	         px          cursor          state_cursor       	   dir_work          filename_state          file_ipset       	   file_log          ipset_name          rttable_name          ipset_connreset_file          ipset_connreset_name          fwmark          g_debug (      	   fd_debug )          