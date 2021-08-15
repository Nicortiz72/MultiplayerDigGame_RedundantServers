require('socket');
myserv = io.read();
port=4040;

enable={1,1,1,1,1};
dservers={"192.168.1.28","192.168.1.174","192.168.1.176","192.168.1.177","192.168.1.178"}
servers={}
N=4

server = socket.bind(myserv, port);
io.write("Waiting for client: "..port.."\n");
cnx = server:accept();
master=cnx:receive();
--cnx:settimeout(0.3);
users={cnx}


------  GAME  -------
---------------------

function winner()
  local b=1
  local win=6
  while players[b] do
    if(players[b][3]==1) then
      if(win==6) then win=b else win=0 end
    end
    b=b+1
  end
  return win
end


fi=1;
local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do
    if(fi<=N) then
    	enable,servers=Whoi(port,enable,dservers,myserv,servers,fi);
    	fi=fi+1
    	--if(fi==N+1) then fi=1 end
    end
  end
end


function init_space(msg)
  -- ' ' : 0 ; '#' : -1 ; '{}'.format(n) : n ; '@' : -2
  space = {} ; space[1] = {}
  if msg:len() == 0 then
    for j=1,m do space[1][j] = " " end
    for i=2,n do
      space[i] = {}
      for j=1,m do
        space[i][j] = "#"
      end
    end
  else
    z=1
    for i=1,(n*m)-2,m do
      space[z]={}
      for j=1,m do
          space[z][j]=msg:sub(i+j-1,i+j-1)
      end
      z=z+1
    end
  end
end

function space_to_str()
  local str = ""
  for i=1,n do
    for j=1,m do
    	str = str..space[i][j]
    end
  end
  return str
end

function init_players()
  players = {}
  for i=1,n_players do
    -- players[i] = {i,j,is_live,score}
    local px = math.floor(m/n_players-2)*i
    space[1][px],players[i] = i,{1,px,1,0}
  end
end

function init_enemies()
  enemies = {}
  for i=1,table.getn(en_px) do
    -- enemies[i] = {posx,posy,last_move}
    space[en_py[i]][en_px[i]],enemies[i] = "@",{en_py[i],en_px[i],0}
    -- never pass the limit of the space
    space[en_py[i]][en_px[i]+1] = " " ; space[en_py[i]][en_px[i]-1] = " "
    space[en_py[i]][en_px[i]+2] = " " ; space[en_py[i]][en_px[i]-2] = " "
  end
end

reverse={2,1,4,3}
-- r l d u
function enemies_move()
  for e=1,table.getn(enemies) do
    local r,c,lm=enemies[e][1],enemies[e][2],enemies[e][3]
    local can={};
    for i=1,4 do
      local dc,dr=en_deltac[i]+c,en_deltar[i]+r
      if 0<dr and dr<=n and 0<dc and dc<=m and space[dr][dc]~="#" and space[dr][dc]~="@" then
        if(lm==0 or not(reverse[lm]==i)) then can[#can+1]=i end
      end
    end
    if(#can > 0) then b=math.random(#can);a=can[b] else a=reverse[lm] end
    dc,dr=en_deltac[a]+c,en_deltar[a]+r
    if(space[dr][dc]~=" " and players[tonumber(space[dr][dc])]) then players[tonumber(space[dr][dc])][3] = 0 end
    space[r][c],space[dr][dc] = " ","@"
    enemies[e] = {dr,dc,a}
  end
end

function player_move(key,i_player)
  local r,c,live = players[i_player][1],players[i_player][2],players[i_player][3]
  local score = players[i_player][4]
  if live~=0 then
    local dr,dc = pl_deltar[key],pl_deltac[key]
    if 0<r+dr and r+dr<=n and 0<c+dc and c+dc<=m then
      if space[r+dr][c+dc]=="@" then
        space[r][c] = 0
        players[i_player][3] = 0 
      else
        space[r][c],space[r+dr][c+dc] = " ",tostring(i_player)
        players[i_player] = {r+dr,c+dc,live,score}
      end
    end
  end
end

function load()
  init_space("")
  init_players()
  init_enemies()
end
function reload()
  enemies={}
  players={}
  ze=1;zpm=0
  for i=1,n do
  	for j=1,m do
  		if(space[i][j]=="@") then
  			enemies[ze]={i,j,0}
  			ze=1+ze
  		elseif(space[i][j]=="1" or space[i][j]=="2" or space[i][j]=="3" or space[i][j]=="4") then
  			tmp=tonumber(space[i][j])
  			players[tmp]={i,j,1,0}
  		end
  	end
  end
  for i=1,n_players do
  	if(not(players[i])) then players[i]={1,1,0,0} end
  end
end

----------------------------------------------
------------------ ARCHIVOS ------------------

function save(msg2)
  arc=io.open("save.txt","w")
  arc:write(msg2.."\n")
  arc:close()
end

function loadS()
  arc=io.open("save.txt","r")
  msg2=arc:read()
  arc:close()
  init_space(msg2)
  reload()
end

---------------------------------------------
------------------- RED --------------------

first=10
function SearchUsers(users)
	server:settimeout(0.3);
	cont=2;
	for i=1,first do
		lister=server:accept();
		if(lister) then
      tmpm=lister:receive();
      tmp=(tmpm:sub(9,9))
      print("-->"..tmpm)
      if(tmp=="0" or tmp=="") then
        users[cont]=lister
        cont=cont+1
			else
        users[tonumber(tmp)]=lister
      end
		end
	end
	return users
end
function Who(port,enable,dservers,myserv,servers)
  enable={1,1,1,1,1}
	for i=1,N do
    servers[i]=socket.tcp()
		servers[i]:settimeout(1)
		if(myserv==dservers[i]) then enable[i] = 0 end
		if(enable[i]==1) then
			if(not(servers[i]:connect(dservers[i], port))) then 
				enable[i]=0;
			else
				servers[i]:send("%%Slave\n");
			end
		end
	end
	return enable,servers;
end
function Whoi(port,enable,dservers,myserv,servers,i)
	enable[i]=1
  servers[i]=socket.tcp()
	servers[i]:settimeout(0.1)
	if(myserv==dservers[i]) then enable[i] = 0 end
	if(enable[i]==1) then
		if(not(servers[i]:connect(dservers[i], port))) then 
			enable[i]=0;
		else
			servers[i]:send("%%Slave\n");
		end
	end
	return enable,servers;
end

function distribution(msg2)
  --enable,servers=Who(port,enable,dservers,myserv,servers);
  for i=1,N do
  	if(enable[i]==1) then
  		servers[i]:send(msg2.."\n");
  	end
  end
  fi=1
end
function Master()
	enable,servers=Who(port,enable,dservers,myserv,servers);
	users=SearchUsers(users);
  us=1
	while users[us] do users[us]:send("%%Ready\n");us=us+1 end
	io.write("Connected \n")
	n_players=us-1;
	if(reuse) then reload() else load() end
	while true do
		mov={};
		us=1;
		while users[us] do
			users[us]:settimeout(0.05);
			msg=users[us]:receive();
			if(msg) then
				if(not(msg == "%%Slave") and #msg == 1) then
					mov[us]=msg;
				end
			end
			us=us+1;
		end
    after=0
		for e=1,n_players do
      if(mov[e]) then
        if(mov[e]=="G") then after=1
        elseif(mov[e]=="L") then after=2
        elseif(not(mov[e]=="N")) then player_move(tonumber(mov[e]),e) end
      end
		end
		enemies_move()
		msg=space_to_str()

    if(after==1) then save(msg)
    elseif(after==2) then loadS();msg=space_to_str() end

		u=1
    ttmp=tostring(winner())
		while users[u] do users[u]:send(msg..tostring(u)..ttmp.."\n");u=u+1 end
    if(not(after==0)) then aftertmp = after end
		if(fi==N+1) then distribution(msg..aftertmp..n_players);aftertmp=0 end
		sleep(0.05)
	end
end
aftertmp=0

function Slave()
  first=3
  init_space("")
  server:settimeout(0.3);
  while true do
    cnx = server:accept();
    if(cnx) then msg = cnx:receive(); else msg=nil end
    if(msg) then
      if((msg == "%%Slave")) then msg = cnx:receive() end
      if(msg) then
        if(msg:sub(1,8)=="%%Master") then
          master=msg;
          tmp=(msg:sub(9,9))
          if(tmp=="0" or tmp=="") then users[1]=cnx else users[tonumber(tmp)]=cnx end
          break;
        elseif(not(msg == "%%Slave") and not(msg:sub(1,8) == "%%Master")) then
          after=msg:sub(lat,lat)
          n_players=tonumber(msg:sub(lat+1,lat+1))
          init_space(msg)
          if(after=="1") then save(msg)
          elseif(after=="2") then loadS() end
        end 
      end
    end
  end
end
-------------------------
----- game variables ----

n,m = 25,50
lat=(n*m)+1
en_px = {12,37,12,37}  -- init enemie Columns
en_py = {6,11,17,21}  -- init enemie Rows
en_deltar = {-1, 1, 0, 0}
en_deltac = { 0, 0,-1, 1}
pl_deltar = {-1, 1, 0, 0}
pl_deltac = { 0, 0,-1, 1}

-------------------------

z=1;
reuse=false
while true do
  print(master)
  if(master:sub(1,8)=="%%Master") then
    Master()
  else
    reuse=true
    Slave()
  end
end

