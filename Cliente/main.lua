socket=require('socket')
start=false
port=4040
enable={1,1,1,1,1};
msgG=false
dservers={"192.168.1.174","192.168.1.28","192.168.1.176","192.168.1.177","192.168.1.178"}
N=4
servers={}
n,m=25,50
ciclo=-1
id_player=0
win="0"

function Who(port,enable,dservers,servers)
	z=-1;
	enable={1,1,1,1,1}
	for i=1,N do
		servers[i]=socket.tcp()
		servers[i]:settimeout(1)
		if(enable[i]==1) then
			if(not(servers[i]:connect(dservers[i],port))) then 
				enable[i]=0;
			else
				if z==-1 then
					servers[i]:send("%%Master"..tostring(id_player).."\n")
					z=i
					break
				end
			end
		end
	end
	return enable,servers,z;
end

function getKey()
	key="N";
	if love.keyboard.isDown("up")  then
		key="1";
	elseif love.keyboard.isDown("down") then
		key="2";
	elseif love.keyboard.isDown("left") then
		key="3";
	elseif love.keyboard.isDown("right") then
		key="4";
	elseif love.keyboard.isDown("g")  then
		key="G";
	elseif love.keyboard.isDown("l") then
		key="L";
	end
	return key
end

function love.draw()
  --font = love.font.newFontData("ClearType")
  --love.graphics.setFont(font)
	if(msgG) then
	  love.graphics.setColor(1, 0, 0, 1)
	  love.graphics.print("Dig Dog: Q.P.R.",320,30,0,2)
	  if(not(win=="0")) then
	  	love.graphics.setColor(0, 0, 1, 1)
	  	if(win=="6") then love.graphics.print("DRAW",320,505,0,2)
	  	else love.graphics.print("The Winner is "..win,320,505,0,2) end
	  end
	  love.graphics.setColor(1, 1, 1, 1)
	  for i=1,n do
	    love.graphics.printf(space[i],150,80+(i*15),500,"justify")
	  end
	else
		love.graphics.print("Esperando Servidor"..tostring(ciclo),0,0,0,2)
	end
end

function init_space(msg)
  -- ' ' : 0 ; '#' : -1 ; '{}'.format(n) : n ; '@' : -2
  space = {} ; space[1] = {}
  if msg:len() == 0 then
    for j=1,m do space[1][j] = 0 end
    for i=2,n do
      space[i] = {}
      for j=1,m do
        space[i][j] = -1
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
ciclo=-1
lat=(n*m)+1
function love.update(dt)
	if(ciclo==0) then
		enable,servers,actual=Who(port,enable,dservers,servers)
		msg=nil;
		flt=false;
		if(not(actual==-1)) then ciclo=1 end
	elseif(ciclo==1) then
		if(actual==-1) then ciclo=-1;return end
		servers[actual]:settimeout(90);
		servers[actual]:receive();
		servers[actual]:settimeout(60);
		state=1;
		if(state) then ciclo=2 end
	elseif(ciclo==2) then
		if(flt) then 
			servers[actual]:send(msg.."\n"); 
			state=servers[actual]:receive();
			if(not(state)) then ciclo=3;return end
			flt=false;
		end
		msg=getKey()
		servers[actual]:send(msg.."\n");
		state=servers[actual]:receive();
		if(state) then 
			init_space(state);
			id_player=state:sub(lat,lat)
			win=state:sub(lat+1,lat+1)
			ciclo=2 
		else ciclo=3 end
		msgG=true

	elseif(ciclo==3) then
		msgG=false
		enable,servers,actual=Who(port,enable,dservers,servers)
		flt=true;
		ciclo=1
	end
end

love.graphics.setBackgroundColor(0,0,0)
for i=1,N do servers[i]=socket.tcp(); end

ciclo=0
