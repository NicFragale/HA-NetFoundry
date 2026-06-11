#!/usr/bin/with-contenv bashio
####################################################################################################
# 20260601 - Written by Nic Fragale @ NetFoundry.
MyName="zetdisplay.sh"
MyPurpose="Ziti-Edge-Tunnel Runtime Display."
####################################################################################################
#set -e -u -o pipefail
[[ ${ZITI_ENV_LOG:-INFO} == "DEBUG" ]] &&
	bashio::log.info "MyName: ${MyName}" &&
	bashio::log.info "MyPurpose: ${MyPurpose}"

####################################################################################################
# Functions
####################################################################################################
function ZET_Status() {
	local ZETSocksDir="/tmp/.ziti"
	local ZETSock="${ZETSocksDir}/ziti-edge-tunnel.sock"
	local ZETResults

	# Find the ZET socket or die.
	if [[ ! -e ${ZETSock} ]]; then
		ZETSock="$(find / -name ziti-edge-tunnel.sock 2>/dev/null)"
		if [[ -e ${ZETSock} ]]; then
			ZETSocksDir="${ZETSock%\/*}"
		else
			printf "<div class=\"summary-row\"><div class=\"stat-card stat-card-error\"><div class=\"stat-label\">ZET Status</div><div class=\"stat-card-value\"><span class=\"FG-BLACK BG-YELLOW\">Socket not found &mdash; please wait or restart.</span></div></div></div>"
			return
		fi
	fi

	# Set the directory to work from.
	local QueryCommand="{\"Command\":\"ZitiDump\",\"Data\":{\"DumpPath\":\"${ZETSocksDir}\"}}"

	# Session history: completed bytes by service; active snapshot: per-child bytes from last poll.
	local ZETHistFile="${ZETSocksDir}/zt-session-history.log"
	local ZETActiveFile="${ZETSocksDir}/zt-session-active.log"
	# Bump sentinel to v3 — resets files for the per-child-ID tracking design.
	local ZETHistGen="${ZETSocksDir}/zt-history-gen-v3"
	if [[ ! -f "${ZETHistGen}" ]]; then
		rm -f "${ZETHistFile}" "${ZETActiveFile}" "${ZETSocksDir}/zt-history-gen" "${ZETSocksDir}/zt-history-gen-v2" 2>/dev/null
		touch "${ZETHistFile}" "${ZETActiveFile}" "${ZETHistGen}" 2>/dev/null
	fi
	touch "${ZETHistFile}" "${ZETActiveFile}" 2>/dev/null

	# Clean up any stale dump files before requesting a fresh one.
	rm -f "${ZETSocksDir}"/*.ziti 2>/dev/null

	# Check for the presence of the socket that ZET creates when running.
	if [[ -e "${ZETSock}" ]]; then

		# Send the command to the ZET socket (with timeout to avoid hanging).
		if ! echo "${QueryCommand}" | timeout 5 socat - UNIX-CONNECT:"${ZETSock}" >/dev/null 2>&1; then
			printf "<div class=\"summary-row\"><div class=\"stat-card stat-card-error\"><div class=\"stat-label\">ZET Status</div><div class=\"stat-card-value\"><span class=\"FG-BLACK BG-YELLOW\">Socket not responding &mdash; try restarting.</span></div></div></div>"
			return
		fi
		readarray -t ZETResults < <(find "${ZETSocksDir}" -name "*.ziti" -type f 2>/dev/null)

		# Initial analysis.
		if [[ ${#ZETResults[*]} -lt 1 ]]; then
			printf "<div class=\"summary-row\"><div class=\"stat-card stat-card-error\"><div class=\"stat-label\">ZET Status</div><div class=\"stat-card-value\"><span class=\"FG-BLACK BG-YELLOW\">Query returned no data.</span></div></div></div>"
			return
		fi

		# Read kernel tunnel interface byte counters for accurate throughput charting.
		local ZitiIF ZitiIFTX ZitiIFRX
		ZitiIF="$(ls /sys/class/net/ 2>/dev/null | grep -m1 '^ziti')"
		if [[ -n "${ZitiIF}" ]]; then
			ZitiIFTX="$(cat "/sys/class/net/${ZitiIF}/statistics/tx_bytes" 2>/dev/null)"
			ZitiIFRX="$(cat "/sys/class/net/${ZitiIF}/statistics/rx_bytes" 2>/dev/null)"
		fi

		# Begin the analysis and output it.
		for ((i=0; i<${#ZETResults[*]}; i++)); do

			awk -v ZITICONTEXT_COUNTER="$((i + 1))" -v ZITICONTEXT_COUNTEREND="${#ZETResults[*]}" -v HISTFILE="${ZETHistFile}" -v ACTIVEFILE="${ZETActiveFile}" -v KERN_TX="${ZitiIFTX}" -v KERN_RX="${ZitiIFRX}" '

				function JOINARRAY(INPUTARRAY, DELIM, RESULTSCALAR, i, n) {
					RESULTSCALAR = ""
					n = length(INPUTARRAY)
					for (i = 1; i <= n; i++) {
						if (i == 1) {
							RESULTSCALAR = INPUTARRAY[i]
						} else {
							RESULTSCALAR = RESULTSCALAR DELIM INPUTARRAY[i]
						}
					}
					return RESULTSCALAR
				}

				function CONCATARRAY(ARRAY_A,ARRAY_B,ARRAY_C) {
					ARRAY_GLOBALCOUNTER=0
					for (i in ARRAY_A) {
						ARRAY_C[++ARRAY_GLOBALCOUNTER]=ARRAY_A[i]
					}
					for (i in ARRAY_B) {
						ARRAY_C[++ARRAY_GLOBALCOUNTER]=ARRAY_B[i]
					}
				}

				function FMT_BYTES(n,   v) {
					v = n+0
					if (v >= 1073741824) return sprintf("%.1f GB", v/1073741824)
					if (v >= 1048576)    return sprintf("%.1f MB", v/1048576)
					if (v >= 1024)       return sprintf("%.1f KB", v/1024)
					return v " B"
				}

				function FMT_DURATION(secs,   s, d, h, m) {
					s = secs+0
					d = int(s / 86400); s -= d * 86400
					h = int(s / 3600);  s -= h * 3600
					m = int(s / 60)
					if (d > 0) return d "d" h "h"
					if (h > 0) return h "h" m "m"
					if (m > 0) return m "m"
					return s "s"
				}

				function READYSAVE(SAVE_SWITCHING) {
					if (SAVE_SWITCHING == "ZITICONTEXT" ) {
						ZITICONTEXT_REPORT[++ZITICONTEXTS]=ZITI_IDENTITYNAME","ZITI_IDENTITY
					} else if (SAVE_SWITCHING == "SERVICES" ) {
						SVC_NAME_BY_ID[SERVICE_IDENTITY] = SERVICE_NAME
						if (SERVICE_TYPE == "DIALONLY" || SERVICE_TYPE == "DIALBIND") {
							SERVICE_DIALREPORT[++INCRD]=SERVICE_IDENTITY","SERVICE_TYPE","SERVICE_NAME","SERVICE_CLIENTFULLHOST","SERVICE_SERVERFULLHOST
						} else if (SERVICE_TYPE == "BINDONLY") {
							SERVICE_BINDREPORT[++INCRB]=SERVICE_IDENTITY","SERVICE_TYPE","SERVICE_NAME","SERVICE_CLIENTFULLHOST","SERVICE_SERVERFULLHOST
						}
					} else if (SAVE_SWITCHING == "CONNECTIONS" ) {
						CONNECTION_REPORT[++CONNECTION_COUNTER]=CONNECTION_NUMBER","CONNECTION_SERVICENAME","CONNECTION_TERMINATORS","toupper(CONNECTION_STATE)","CONNECTION_CHANNELROUTER
					} else if (SAVE_SWITCHING == "CHILDREN" ) {
						CHILDREN_REPORT[++CHILD_COUNTER]=CONNECTION_CHILDTOCONNECTIONNUMBER","CONNECTION_CHILDNUMBER","toupper(CONNECTION_CHILDSTATE)","CONNECTION_CHILDCALLERID","CONNECTION_CHILDCHANNELROUTER","CONNECTION_CHILDINFO_A
					} else if (SAVE_SWITCHING == "CHANNELS" ) {
						CHANNEL_REPORT[++CHANNEL_COUNTER]=CHANNEL_NUMBER","CHANNEL_ROUTER","toupper(CHANNEL_STATE)","CHANNEL_LATENCY","CHANNEL_CONNECTED_TIME
					}
				}

				function CONCLUDESECTION(a,b) {
					if (a == "ZITICONTEXT") {
						READYSAVE("ZITICONTEXT")
						IN_CTRL_SECTION=0
					} else if (a == "SESSION") {
					} else if (a == "SESSIONINFO") {
					} else if (a == "SERVICES") {
						READYSAVE("SERVICES")
					} else if (a == "NETSESSIONS") {
					} else if (a == "CHANNELS") {
					} else if (a == "CONNECTIONS") {
					} else if (a == "CHILDREN") {
					}
					return b
				}

				function FINDVALUE(CONTEXT, PATTERNKEY, TRIGGER) {
					# TRIGGER[VALUE]
					if (PATTERNKEY == "A") {
						FINDREGEX=TRIGGER "\\[([^\\]]+)\\]"
					# TRIGGER[VALUEs]
					} else if (PATTERNKEY == "B") {
						FINDREGEX=TRIGGER "\\[([^\\]]+)s\\]"
					# TRIGGER: VALUE
					} else if (PATTERNKEY == "C") {
						FINDREGEX=TRIGGER ":[[:space:]]+(.*)\\["
					# TRIGGER(VALUE)
					} else if (PATTERNKEY == "D") {
						FINDREGEX=TRIGGER "\\(([^\\]]+)\\)"
					# VALUE:TRIGGER
					} else if (PATTERNKEY == "E") {
						FINDREGEX="(.*):.*" TRIGGER
					# config[TRIGGER]=VALUE
					} else if (PATTERNKEY == "F") {
						FINDREGEX="config\\[" TRIGGER "\\]=(.*)"
					# ch[TRIGGER](VALUE1@VALUE2)
					} else if (PATTERNKEY == "G1") {
						FINDREGEX="ch\\[" TRIGGER "\\]\\((.*)@.*\\)"
					# ch[TRIGGER](VALUE1@VALUE2)
					} else if (PATTERNKEY == "G2") {
						FINDREGEX="ch\\[" TRIGGER "\\]\\(.*@(.*)\\)"
					# "TRIGGER": [VALUE]
					} else if (PATTERNKEY == "H" || PATTERNKEY == "H1") {
						FINDREGEX="\"" TRIGGER "\":\\s\\[?\\s*(\"?[^]]*\"?)\\s\\]?"
					# { "high": VALUE, "low": VALUE }, { "high": VALUE, low: VALUE }
					} else if (PATTERNKEY == "H2") {
						FRESULT=""
						while (match(RESULT, /{\s*high:\s*([0-9]+),\s*low:\s*([0-9]+)\s*}/, arr)) {
							high=arr[1]
							low=arr[2]
							if (low == high) {
								FRESULT=FRESULT (FRESULT == "" ? "" : ",") low
							} else {
								FRESULT=FRESULT (FRESULT == "" ? "" : ",") low "-" high
							}
							RESULT=substr(RESULT, RSTART + RLENGTH)
						}
						return FRESULT
					# "TRIGGER": VALUE
					} else if (PATTERNKEY == "I") {
						FINDREGEX="\"" TRIGGER "\":\\s([^}|^,]+)\\s\\}"
					# "TRIGGER": "VALUE"
					} else if (PATTERNKEY == "J") {
						FINDREGEX="\"" TRIGGER "\":\\s\"([^\"]+)\","
					}

					match(CONTEXT, FINDREGEX, STOREARRAY)
					RESULT=STOREARRAY[1]
					gsub("\"","",RESULT)
					if (PATTERNKEY == "H1") {
						RESULT=FINDVALUE(RESULT, "H2", "")
						return RESULT
					} else {
						return RESULT
					}
				}

				# ── Completed history file: SERVICE|SENT|RECV ──────────────────────────
				FILENAME == HISTFILE {
					if (NF > 0 && $0 != "") {
						n = split($0, h, "|")
						if (n >= 3) {
							hkey = h[1]
							HIST_SVC[hkey]  = h[1]
							HIST_SENT[hkey] = h[2]+0
							HIST_RECV[hkey] = h[3]+0
						}
					}
					next
				}

				# ── Active snapshot from previous poll: CHILD_ID|SERVICE|SENT|RECV ─────
				FILENAME == ACTIVEFILE {
					if (NF > 0 && $0 != "") {
						n = split($0, h, "|")
						if (n >= 4) {
							PREV_SVC[h[1]]  = h[2]
							PREV_SENT[h[1]] = h[3]+0
							PREV_RECV[h[1]] = h[4]+0
						}
					}
					next
				}

				BEGIN {
					CURRENTSECTION="INIT"
					ARRAY_GLOBALCOUNTER=0
					CONNECTION_COUNTER=0
					CHILD_COUNTER=0
					CHANNEL_COUNTER=0
					SESSION_COUNTER=0
					CTRL_COUNT=0
					IN_CTRL_SECTION=0
				}

				{
					# Section Switching.
					if (/^Ziti Context:$/) {
						CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"ZITICONTEXT")
					} else if (/^Session:$/) {
						CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"SESSION")
					} else if (/^Session Info:$/) {
						CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"SESSIONINFO")
					} else if (/^Services:$/) {
						CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"SERVICES")
					} else if (/^Sessions:$/) {
						CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"NETSESSIONS")
					} else if (/^Channels:$/) {
						CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"CHANNELS")
					} else if (/^Connections:$/) {
						CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"CONNECTIONS")
					}

					# ZITI CONTEXT SECTION #
					if (/^Identity:/) {

						ZITI_IDENTITYNAME=FINDVALUE($0, "C", "Identity")
						ZITI_IDENTITY=FINDVALUE($0, "A", FINDVALUE($0, "C", "Identity"))

					# Controller connections.
					# Old format (pre-1.15): Controller[name]: [version] url online[Y/N] — all on one line.
					# New format (1.15+): Controller[name]: [version] primary_url — header only,
					#   followed by indented sub-lines: "  UUID: online[Y] https://URL"
					} else if (/^Controller\[/) {
						if (/online\[/) {
							# Old single-line format
							CTRL_ONLINE=FINDVALUE($0, "A", "online")
							CTRL_URL=gensub(/^Controller\[[^\]]+\]:[[:space:]]+\[[^\]]+\][[:space:]]+(https?:\/\/[^[:space:]]+).*/, "\\1", "1")
							CTRL_HOST=gensub(/https?:\/\/([^\/]+).*/, "\\1", "1", CTRL_URL)
							CTRL_REPORT[++CTRL_COUNT]=CTRL_HOST","(CTRL_ONLINE=="Y" ? "ONLINE" : "OFFLINE")
							CTRL_PRIMARY_HOST=CTRL_HOST
							IN_CTRL_SECTION=0
						} else {
							# New 1.15+ multi-line format: header URL is the currently-active controller
							CTRL_PRIMARY_URL=gensub(/^Controller\[[^\]]+\]:[[:space:]]+\[[^\]]+\][[:space:]]+(https?:\/\/[^[:space:]]*).*/, "\\1", "1")
							CTRL_PRIMARY_HOST=gensub(/https?:\/\/([^\/]+).*/, "\\1", "1", CTRL_PRIMARY_URL)
							IN_CTRL_SECTION=1
						}
					} else if (IN_CTRL_SECTION && /^\s+[0-9a-f][0-9a-f-]*:.*online\[/) {
						# Indented controller endpoint sub-line: "  UUID: online[Y] https://URL"
						CTRL_ONLINE=FINDVALUE($0, "A", "online")
						CTRL_URL=gensub(/^\s+[^:]+:[[:space:]]+[^[:space:]]+[[:space:]]+(https?:\/\/[^[:space:]]*).*/, "\\1", "1")
						CTRL_HOST=gensub(/https?:\/\/([^\/]+).*/, "\\1", "1", CTRL_URL)
						CTRL_REPORT[++CTRL_COUNT]=CTRL_HOST","(CTRL_ONLINE=="Y" ? "ONLINE" : "OFFLINE")

					# SERVICES SECTION #
					} else if (/dial=.*,bind=.*/) {

						if (SERVICE_TYPE)
							READYSAVE("SERVICES")
						if (/dial=true,bind=false/) {
							SERVICE_TYPE="DIALONLY"
						} else if (/dial=false,bind=true/) {
							SERVICE_TYPE="BINDONLY"
						} else if (/dial=true,bind=true/) {
							SERVICE_TYPE="DIALBIND"
						}

						# New format: "ServiceName {id:HEX} perm:(...)" – strip everything from first {/[ onward.
						# Old format fallback: use pattern E.
						if (match($0, /^(.*)\s+[{\[]/, svcm))
							SERVICE_NAME=svcm[1]
						else
							SERVICE_NAME=FINDVALUE($0, "E", "perm")
						SERVICE_IDENTITY=FINDVALUE($0, "A", "id")

					} else if (/^\s+config\[host.v1\]/) {

						if (/\"allowedAddresses\"/) {
							SERVICE_SERVERHOST=FINDVALUE($0, "H", "allowedAddresses")
						} else {
							SERVICE_SERVERHOST=FINDVALUE($0, "J", "address")
						}
						gsub(/,/,"|",SERVICE_SERVERHOST)

						if (/\"allowedPortRanges\"/) {
							SERVICE_SERVERPORT=FINDVALUE($0, "H1", "allowedPortRanges")
						} else if (match($0, /"port":[[:space:]]*([0-9]+)/, pm)) {
							# Old-style flat "port": N — pattern I fails when port is not last
							# before }, so use a direct numeric match instead.
							SERVICE_SERVERPORT=pm[1]
						} else {
							SERVICE_SERVERPORT=""
						}
						gsub(/,/,"|",SERVICE_SERVERPORT)

						if (/\"allowedProtocols\"/) {
							SERVICE_SERVERPROTOCOL=FINDVALUE($0, "H", "allowedProtocols")
						} else {
							# Old-style flat "protocol": "tcp" — use pattern J (exact quoted match).
							# The previous double-assignment bug overwrote SERVICE_SERVERHOST via
							# pattern H, which greedily captured the entire rest of the line.
							SERVICE_SERVERPROTOCOL=FINDVALUE($0, "J", "protocol")
						}
						gsub(/,/,"|",SERVICE_SERVERPROTOCOL)

						SERVICE_SERVERFULLHOST="["SERVICE_SERVERHOST"]:["SERVICE_SERVERPORT"]/["SERVICE_SERVERPROTOCOL"]"
						gsub(/,/," ",SERVICE_SERVERFULLHOST)

						# ZET 1.15+ emits "forwardAddress": true (space after colon);
						# older used "forwardPort":true (no space). Handle both.
						if (/\"forwardPort\":[ ]*true/ || /\"forwardAddress\":[ ]*true/) {
							SERVICE_SERVERFORWARDPORT="<span class=\"FG-GREEN\">YES</span>"
						} else {
							SERVICE_SERVERFORWARDPORT="<span class=\"FG-GREY\">NO</span>"
						}

						if (/\"forwardProtocol\":[ ]*true/) {
							SERVICE_SERVERFORWARDPROTOCOL="<span class=\"FG-GREEN\">YES</span>"
						} else {
							SERVICE_SERVERFORWARDPROTOCOL="<span class=\"FG-GREY\">NO</span>"
						}

						SERVICE_SERVERFULLHOST=SERVICE_SERVERFULLHOST" (FWD PORT="SERVICE_SERVERFORWARDPORT"/PROTO="SERVICE_SERVERFORWARDPROTOCOL")"

					} else if (/^\s+config\[intercept.v1\]/) {

						SERVICE_CLIENTHOST=FINDVALUE($0, "H", "addresses")
						split(SERVICE_CLIENTHOST,ARRAY_CLIENTHOSTS,",")
						for (EACH_CLIENTHOST in ARRAY_CLIENTHOSTS) {
							FINALRESOLVE=ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]
							gsub(/\*\.?/,"",FINALRESOLVE)
							if (SERVICE_TYPE == "DIALONLY" || SERVICE_TYPE == "DIALBIND") {
								if (match(ARRAY_CLIENTHOSTS[EACH_CLIENTHOST],/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)) {
									ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]=ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]"@IPONLY:"ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]
								} else {
									RUNCOMMAND="echo -n TRYDNS:$(dig +short "FINALRESOLVE" 2>&1)"
									RUNCOMMAND | getline EACH_CLIENTHOSTRESOLVED
									close(RUNCOMMAND)
									gsub(/ /,"|",EACH_CLIENTHOSTRESOLVED)
									ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]=ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]"@"EACH_CLIENTHOSTRESOLVED
								}
							}
						}

						SERVICE_CLIENTHOST="["JOINARRAY(ARRAY_CLIENTHOSTS,"|")"]"
						SERVICE_CLIENTPORT=FINDVALUE($0, "H1", "portRanges")
						gsub(/,/,"|",SERVICE_CLIENTPORT)
						SERVICE_CLIENTPROTOCOL=FINDVALUE($0, "H", "protocols")
						gsub(/,/,"|",SERVICE_CLIENTPROTOCOL)
						SERVICE_CLIENTFULLHOST=SERVICE_CLIENTHOST":["SERVICE_CLIENTPORT"]/["SERVICE_CLIENTPROTOCOL"]"

					} else if (/^\s+config\[ziti-tunneler-server.v1\]/) {

						SERVICE_SERVERHOST=FINDVALUE($0, "J", "hostname")
						SERVICE_SERVERPORT=FINDVALUE($0, "I", "port")
						SERVICE_SERVERPROTOCOL=FINDVALUE($0, "J", "protocol")
						SERVICE_SERVERFULLHOST="["SERVICE_SERVERHOST"]:["SERVICE_SERVERPORT"]/["SERVICE_SERVERPROTOCOL"]"

					} else if (/^\s+config\[ziti-tunneler-client.v1\]/) {

						SERVICE_CLIENTHOST=FINDVALUE($0, "J", "hostname")
						SERVICE_CLIENTPORT=FINDVALUE($0, "I", "port")
						if (SERVICE_TYPE == "DIALONLY" || SERVICE_TYPE == "DIALBIND") {
							if (match(SERVICE_CLIENTHOST,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)) {
								SERVICE_CLIENTHOST=SERVICE_CLIENTHOST"@"SERVICE_CLIENTHOST
							} else {
								RUNCOMMAND="echo -n TRYDNS:$(dig +short "SERVICE_CLIENTHOST" 2>&1)"
								RUNCOMMAND | getline CLIENTHOSTRESOLVED
								close(RUNCOMMAND)
								gsub(/ /,"|",CLIENTHOSTRESOLVED)
								SERVICE_CLIENTHOST=SERVICE_CLIENTHOST"@IPONLY:"CLIENTHOSTRESOLVED
							}
						}
						SERVICE_CLIENTFULLHOST="["SERVICE_CLIENTHOST":["SERVICE_CLIENTPORT"]/[tcp]"

					# POSTURE QUERIES SECTION #
					} else if (/^\s+posture/) {

						# NEEDS WORK.

					# NETSESSIONS SECTION #
					} else if (/.*: service_id\[/) {

						SESS_SVC_ID = FINDVALUE($0, "A", "service_id")
						getline SESS_LINE
						SESS_ISS = ""; SESS_EXP = 0; SESS_TYPE = ""
						if (match(SESS_LINE, /"iss":"([^"]+)"/, SMAT)) SESS_ISS = SMAT[1]
						if (match(SESS_LINE, /"exp":([0-9]+)/, SMAT))  SESS_EXP = SMAT[1]+0
						if (match(SESS_LINE, /"z_st":"([^"]+)"/, SMAT)) SESS_TYPE = SMAT[1]
						SESS_ISS_HOST = gensub(/https?:\/\/([^\/]+).*/, "\\1", "1", SESS_ISS)
						SESSION_REPORT[++SESSION_COUNTER] = SESS_SVC_ID","SESS_TYPE","SESS_ISS_HOST","SESS_EXP

					# CHANNELS SECTION #
					} else if (/^ch\[.*\]/) {

						CHANNEL_NUMBER=FINDVALUE($0, "A", "ch")

						# ZET 1.15+: two-line format
						#   ch[N] ROUTER NAME WITH SPACES
						#       connected[Y] version[...] address[...] latency[N] connected[Xs]
						# ZET <1.15: single-line
						#   ch[N](ROUTER@IP) STATE [latency=Xms]
						if (/^ch\[[^\]]+\]\(/) {
							# Old single-line parenthesised format
							CHANNEL_ROUTER=FINDVALUE($0, "D", "ch\\[.*\\]")
							if (match($0,"latency")) {
								CHANNEL_STATE=gensub(/.*\) (.*) \[.*/,"\\1","1")
								CHANNEL_LATENCY=gensub(/.*\[latency=(.*)\].*/,"\\1","1")
							} else {
								CHANNEL_STATE=gensub(/.*\) (.*)/,"\\1","1")
								CHANNEL_LATENCY="NA"
							}
							CHANNEL_CONNECTED_TIME=""
						} else {
							# New two-line format: router name is everything after ch[N]
							CHANNEL_ROUTER=gensub(/^ch\[[^\]]+\]\s*/,"","1")
							# Read the indented detail line
							getline CHAN_DETAIL_LINE
							# connected[Y] = state; latency[N] = ms; connected[NNNs] = uptime
							CHAN_CONN=FINDVALUE(CHAN_DETAIL_LINE, "A", "connected")
							CHANNEL_STATE = (CHAN_CONN == "Y") ? "CONNECTED" : "CONNECTING"
							CHANNEL_LATENCY=FINDVALUE(CHAN_DETAIL_LINE, "A", "latency")
							if (CHANNEL_LATENCY == "") CHANNEL_LATENCY="NA"
							# Extract uptime: the second connected[...] field has a numeric+s value
							if (match(CHAN_DETAIL_LINE, /connected\[([0-9]+)s\]/, cm))
								CHANNEL_CONNECTED_TIME = cm[1]
							else
								CHANNEL_CONNECTED_TIME = ""
						}
						READYSAVE("CHANNELS")

					# CONNECTIONS SECTION #
					} else if (/^conn\[.*\]/) {

						CONNECTION_NUMBER=FINDVALUE($0, "A", "conn")
						CONNECTION_SERVICENAME=FINDVALUE($0, "A", "service")
						CONNECTION_TERMINATORS=FINDVALUE($0, "A", "terminators")
						CONNECTION_STATE=FINDVALUE($0, "A", "state")
						CONNECTION_CHANNELROUTER=FINDVALUE($0, "A", "ch")
						gsub(".*/","",CONNECTION_CHANNELROUTER)
						READYSAVE("CONNECTIONS")
						# DIAL connections (client-side): "conn[N/ID]: state[...] service[...] using ch[...]"
						# Stats are on the next line; there are no child entries — synthesise one.
						if (/using ch\[/) {
							getline DIAL_STATS
							d_sb = 0; d_rb = 0
							if (match(DIAL_STATS, /sent\[([0-9]+)\]/, dm)) d_sb = dm[1]+0
							if (match(DIAL_STATS, /recv\[([0-9]+)\]/, dm)) d_rb = dm[1]+0
							CHILDREN_REPORT[++CHILD_COUNTER] = CONNECTION_NUMBER","CONNECTION_NUMBER","toupper(CONNECTION_STATE)","","CONNECTION_CHANNELROUTER","("sent[" d_sb "] recv[" d_rb "]")
						}

					# CONNECTIONS/CHILDREN SUBSECTION #
					} else if (/^\s+child\[.*\]/) {

						CONNECTION_CHILDTOCONNECTIONNUMBER=CONNECTION_NUMBER
						CONNECTION_CHILDNUMBER=FINDVALUE($0, "A", "child")
						CONNECTION_CHILDSTATE=FINDVALUE($0, "A", "state")
						# New format: caller[NAME]; old format: caller_id[NAME] or caller_id=NAME
						CONNECTION_CHILDCALLERID=FINDVALUE($0, "A", "caller")
						if (CONNECTION_CHILDCALLERID == "")
							CONNECTION_CHILDCALLERID=FINDVALUE($0, "A", "caller_id")
						# New format: ch[FULL_ROUTER_NAME]; old format: ch=ch[N](...)
						CONNECTION_CHILDCHANNELROUTER=FINDVALUE($0, "A", "ch")
						gsub(".*/","",CONNECTION_CHILDCHANNELROUTER)
						getline
						CONNECTION_CHILDINFO_A=gensub(/^[[:blank:]]+(.*)/,"\\1","1")
						READYSAVE("CHILDREN")

					}

				}

				END {
					CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"END")

					SUM_ACTIVE_CONNS=0
					for (c in CHILDREN_REPORT) {
						split(CHILDREN_REPORT[c],PC,",")
						if (PC[3] != "" && PC[3] != "CLOSED" && PC[3] != "TERMINATED") SUM_ACTIVE_CONNS++
					}

					# ── Throughput data for JS chart ─────────────────────────────────────
					# Prefer kernel interface counters (complete, monotonic); fall back to
					# summed connection bytes if the ziti interface was not found.
					if (KERN_TX != "" || KERN_RX != "") {
						chart_tx = KERN_TX+0
						chart_rx = KERN_RX+0
					} else {
						chart_tx = 0; chart_rx = 0
						for (ci in CHILDREN_REPORT) {
							split(CHILDREN_REPORT[ci],PCH,",")
							if (match(PCH[6], /sent\[([0-9]+)\]/, mck)) chart_tx += mck[1]+0
							if (match(PCH[6], /recv\[([0-9]+)\]/, mck)) chart_rx += mck[1]+0
						}
					}
					printf "<div id=\"ZET-THROUGHPUT\" style=\"display:none\" data-sent=\"%d\" data-recv=\"%d\"></div>", chart_tx, chart_rx

					# ── Table-based detail view (replaces tree) ──────────────────────────────
					# Merge DIAL and BIND service arrays for the services table
					CONCATARRAY(SERVICE_DIALREPORT,SERVICE_BINDREPORT,SERVICE_REPORT)

					# Identity block
					for (EACH_ZC in ZITICONTEXT_REPORT) {
						split(ZITICONTEXT_REPORT[EACH_ZC],PZC,",")
						printf "<div class=\"zt-identity-block\">"
						printf "<div class=\"zt-identity-header\">&#x25CF;&nbsp;%s</div>", PZC[1]
					}

					# ── Controllers ──────────────────────────────────────────────────────────
					if (CTRL_COUNT > 0) {
						printf "<div class=\"zt-section\"><div class=\"zt-section-title\">Controllers</div>"
						printf "<table class=\"zt-table\"><thead><tr><th>Controller</th><th class=\"zt-th-sm\">Status</th></tr></thead><tbody>"
						for (ci=1; ci<=CTRL_COUNT; ci++) {
							split(CTRL_REPORT[ci],CPR,",")
							bcls = (CPR[2]=="ONLINE") ? "badge-online" : "badge-offline"
							if (CTRL_PRIMARY_HOST != "" && CPR[1] == CTRL_PRIMARY_HOST)
								printf "<tr><td class=\"zt-mono\">&#x25CF;&nbsp;%s</td><td><span class=\"badge %s\">%s</span></td></tr>", CPR[1], bcls, CPR[2]
							else
								printf "<tr><td class=\"zt-mono\"><span class=\"zt-muted\">&#x25CB;</span>&nbsp;%s</td><td><span class=\"badge %s\">%s</span></td></tr>", CPR[1], bcls, CPR[2]
						}
						printf "</tbody></table></div>"
					}

					# ── Edge Routers ─────────────────────────────────────────────────────────
					printf "<div class=\"zt-section\"><div class=\"zt-section-title\">Edge Routers</div>"
					printf "<table class=\"zt-table\"><thead><tr><th>Router</th><th class=\"zt-th-sm\">Connected</th><th class=\"zt-th-sm\">Latency</th><th class=\"zt-th-sm\">Status</th></tr></thead><tbody>"
					for (ci=1; ci<=CHANNEL_COUNTER; ci++) {
						split(CHANNEL_REPORT[ci],PC,",")
						is_conn = (PC[3] ~ /(^| )CONNECTED$/)
						lat = PC[4]+0
						uptime = PC[5]+0
						if (is_conn) {
							if (lat < 50) lc="lat-good"; else if (lat < 100) lc="lat-warn"; else lc="lat-bad"
							lt = lat "ms"
							bc = "badge-up"; bt = "UP"
							ut = (uptime > 0) ? FMT_DURATION(uptime) : "&mdash;"
						} else {
							lc = "zt-muted"; lt = "&mdash;"
							bc = "badge-connecting"; bt = "CONN"
							ut = "&mdash;"
						}
						printf "<tr><td class=\"zt-mono\">%s</td><td class=\"zt-muted\">%s</td><td class=\"%s\">%s</td><td><span class=\"badge %s\">%s</span></td></tr>", PC[2], ut, lc, lt, bc, bt
					}
					printf "</tbody></table></div>"

					# ── Authorized Services ───────────────────────────────────────────────────
					if (ARRAY_GLOBALCOUNTER > 0) {
						printf "<div class=\"zt-section\"><div class=\"zt-section-title\">Authorized Services</div>"
						printf "<table class=\"zt-table\"><thead><tr><th>Service</th><th class=\"zt-th-sm\">Type</th><th>Address</th></tr></thead><tbody>"
						for (si=1; si<=ARRAY_GLOBALCOUNTER; si++) {
							split(SERVICE_REPORT[si],PS,",")
							if (PS[2]=="DIALONLY")  { bc="badge-dial";  bt="DIAL"; addr=PS[4] }
							else if (PS[2]=="BINDONLY") { bc="badge-bind"; bt="BIND"; addr=PS[5] }
							else { bc="badge-dialbind"; bt="BOTH"; addr=PS[4] }
							# Strip internal annotations, brackets, and normalize to host:port/proto
							addr = gensub(/ \(FWD PORT=.*\)/, "", "1", addr)
							addr = gensub(/@(TRYDNS|IPONLY):[^\]]*/, "", "g", addr)
							addr = gensub(/\[([^\]]*)\]:\[([^\]]*)\]\/\[([^\]]*)\]/, "\\1:\\2/\\3", "g", addr)
							gsub(/\|/, ",", addr)
							printf "<tr><td class=\"zt-mono\">%s</td><td><span class=\"badge %s\">%s</span></td><td class=\"zt-mono\">%s</td></tr>", PS[3], bc, bt, addr
						}
						printf "</tbody></table></div>"
					}

					# ── Active Sessions ──────────────────────────────────────────────────────
					if (SESSION_COUNTER > 0) {
						printf "<div class=\"zt-section\"><div class=\"zt-section-title\">Active Sessions</div>"
						printf "<table class=\"zt-table\"><thead><tr><th>Service</th><th class=\"zt-th-sm\">Type</th><th>Issuer</th><th class=\"zt-th-sm\">Expires</th></tr></thead><tbody>"
						for (ci=1; ci<=SESSION_COUNTER; ci++) {
							split(SESSION_REPORT[ci],SESS,",")
							svc_n = (SESS[1] in SVC_NAME_BY_ID) ? SVC_NAME_BY_ID[SESS[1]] : SESS[1]
							if (SESS[2] == "Dial")      { sbc="badge-dial"; sbt="DIAL" }
							else if (SESS[2] == "Bind") { sbc="badge-bind"; sbt="BIND" }
							else                        { sbc="badge-dialbind"; sbt=SESS[2] }
							exp_secs = SESS[4]+0 - systime()
							if (exp_secs > 86400*2)
								exp_str = FMT_DURATION(exp_secs)
							else if (exp_secs > 0)
								exp_str = "<span class=\"lat-warn\">" FMT_DURATION(exp_secs) "</span>"
							else
								exp_str = "<span class=\"lat-bad\">EXPIRED</span>"
							printf "<tr><td class=\"zt-mono\">%s</td><td><span class=\"badge %s\">%s</span></td><td class=\"zt-mono zt-muted\">%s</td><td class=\"zt-num\">%s</td></tr>",
								svc_n, sbc, sbt, SESS[3], exp_str
						}
						printf "</tbody></table></div>"
					}

					# ── Active Connections — grouped by service ──────────────────────────────
					if (SUM_ACTIVE_CONNS > 0) {
						# First pass: accumulate detail rows per service, preserving insertion order
						delete CONN_ROWS; delete CONN_SVC_SEEN; CONN_SVC_COUNT=0
						delete CONN_SVC_ORDER
						for (ci=1; ci<=CHILD_COUNTER; ci++) {
							split(CHILDREN_REPORT[ci],PCH,",")
							if (PCH[3] == "" || PCH[3] == "CLOSED" || PCH[3] == "TERMINATED") continue
							svc = "&mdash;"
							for (cx=1; cx<=CONNECTION_COUNTER; cx++) {
								split(CONNECTION_REPORT[cx],PCONN,",")
								if (PCONN[1] == PCH[1]) { svc = PCONN[2]; break }
							}
							sb = "&mdash;"; rb = "&mdash;"
							if (match(PCH[6], /sent\[([0-9]+)\]/, sm)) sb = FMT_BYTES(sm[1]+0)
							if (match(PCH[6], /recv\[([0-9]+)\]/, rm)) rb = FMT_BYTES(rm[1]+0)
							if (!(svc in CONN_SVC_SEEN)) {
								CONN_SVC_SEEN[svc] = 1
								CONN_SVC_ORDER[++CONN_SVC_COUNT] = svc
							}
							# For DIAL connections the local identity is the caller; fill it in.
							caller_disp = (PCH[4] != "") ? PCH[4] : ZITI_IDENTITYNAME
							# Show state badge for non-connected states (CloseWrite etc.)
							state_tag = ""
							if (PCH[3] != "CONNECTED" && PCH[3] != "ACCEPTING")
								state_tag = sprintf("&nbsp;<span class=\"badge badge-connecting\">%s</span>", PCH[3])
							CONN_ROWS[svc] = CONN_ROWS[svc] sprintf("<tr class=\"zt-conn-detail\"><td class=\"zt-mono zt-muted\">%s</td><td class=\"zt-mono zt-muted\">%s%s</td><td class=\"zt-num\">%s</td><td class=\"zt-num\">%s</td></tr>", PCH[5], caller_disp, state_tag, sb, rb)
						}
						# Second pass: output grouped table
						printf "<div class=\"zt-section\"><div class=\"zt-section-title\">Active Connections</div>"
						printf "<table class=\"zt-table\"><thead><tr><th>Router</th><th>Caller</th><th class=\"zt-th-sm\">Sent</th><th class=\"zt-th-sm\">Recv</th></tr></thead><tbody>"
						for (si=1; si<=CONN_SVC_COUNT; si++) {
							svc = CONN_SVC_ORDER[si]
							printf "<tr class=\"zt-conn-group\"><td colspan=\"4\" class=\"zt-mono\">%s</td></tr>", svc
							printf "%s", CONN_ROWS[svc]
						}
						printf "</tbody></table></div>"
					}

					# ── Build current active snapshot from dump ──────────────────────────
					# PCH[2] = child[N/UniqueID] value — unique per connection lifetime
					for (ci=1; ci<=CHILD_COUNTER; ci++) {
						split(CHILDREN_REPORT[ci],PCH,",")
						if (PCH[3] == "" || PCH[3] == "CLOSED" || PCH[3] == "TERMINATED") continue
						cid = PCH[2]
						c_svc = ""
						for (cx=1; cx<=CONNECTION_COUNTER; cx++) {
							split(CONNECTION_REPORT[cx],PCONN,",")
							if (PCONN[1] == PCH[1]) { c_svc = PCONN[2]; break }
						}
						if (c_svc == "") continue
						c_sb = 0; c_rb = 0
						if (match(PCH[6], /sent\[([0-9]+)\]/, sm)) c_sb = sm[1]+0
						if (match(PCH[6], /recv\[([0-9]+)\]/, rm)) c_rb = rm[1]+0
						CURR_SVC[cid]  = c_svc
						CURR_SENT[cid] = c_sb
						CURR_RECV[cid] = c_rb
					}

					# ── Detect ended connections: in prev snapshot but gone from dump ──────
					# Their last recorded bytes are now final — commit to completed history.
					for (cid in PREV_SVC) {
						if (!(cid in CURR_SVC)) {
							svc = PREV_SVC[cid]
							HIST_SVC[svc]  = svc
							HIST_SENT[svc] = HIST_SENT[svc]+0 + PREV_SENT[cid]+0
							HIST_RECV[svc] = HIST_RECV[svc]+0 + PREV_RECV[cid]+0
						}
					}

					# ── Persist completed history (ended connections only) ─────────────────
					for (hkey in HIST_SVC) {
						print HIST_SVC[hkey] "|" HIST_SENT[hkey]+0 "|" HIST_RECV[hkey]+0 > HISTFILE
					}
					close(HISTFILE)

					# ── Persist active snapshot for next poll comparison ──────────────────
					for (cid in CURR_SVC) {
						print cid "|" CURR_SVC[cid] "|" CURR_SENT[cid]+0 "|" CURR_RECV[cid]+0 > ACTIVEFILE
					}
					close(ACTIVEFILE)

					# ── Session History display: completed + live bytes per service ────────
					delete DISP_SVC; delete DISP_SENT; delete DISP_RECV
					for (hkey in HIST_SVC) {
						DISP_SVC[hkey]  = HIST_SVC[hkey]
						DISP_SENT[hkey] = HIST_SENT[hkey]+0
						DISP_RECV[hkey] = HIST_RECV[hkey]+0
					}
					for (cid in CURR_SVC) {
						svc = CURR_SVC[cid]
						DISP_SVC[svc]  = svc
						DISP_SENT[svc] = DISP_SENT[svc]+0 + CURR_SENT[cid]+0
						DISP_RECV[svc] = DISP_RECV[svc]+0 + CURR_RECV[cid]+0
					}

					DISP_TOTAL = 0
					for (hkey in DISP_SVC) DISP_TOTAL++
					if (DISP_TOTAL > 0) {
						printf "<div class=\"zt-section\"><div class=\"zt-section-title\">Connection History</div>"
						printf "<table class=\"zt-table\"><thead><tr><th>Service</th><th class=\"zt-th-sm\">Sent</th><th class=\"zt-th-sm\">Recv</th></tr></thead><tbody>"
						for (hkey in DISP_SVC) {
							printf "<tr><td class=\"zt-mono\">%s</td><td class=\"zt-num\">%s</td><td class=\"zt-num\">%s</td></tr>",
								DISP_SVC[hkey],
								FMT_BYTES(DISP_SENT[hkey]+0), FMT_BYTES(DISP_RECV[hkey]+0)
						}
						printf "</tbody></table></div>"
					}

					printf "</div>" # end zt-identity-block



				}

			' "${ZETHistFile}" "${ZETActiveFile}" "${ZETResults[${i}]}" ||
				printf "<span class=\"FG-WHITE BG-RED\">ERROR: Parsing (AWK) failed. Please report this!</span>"

		done

		# Cleanup.
		rm -f "${ZETSocksDir}"/*.ziti 2>/dev/null

	else

		printf "<span class=\"FG-WHITE BG-RED\">Could not find the ZET Socket to connect to!</span>"
		return

	fi

	# Final cleanup.
	rm -f "${ZETSocksDir}"/*.ziti 2>/dev/null
	return
}

####################################################################################################
# MAIN
####################################################################################################
printf "<span id=\"ZETDETAIL\" class=\"FULLWIDTH\">%s</span>" "$(ZET_Status)"
printf "<span id=\"ZETDATE-SYSTEM\" class=\"CENTERDATE FULLWIDTH OPACITY-D\">UPDATED : %s</span>" "$(date -u +'%A, %d-%b-%y %H:%M:%S UTC')"
