--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   bit.lua
* VERSION    :   1.0
* DESCRIPTION:   lib for bit operation, only supported for unsigned int 32.
*
* AUTHOR     :   LiGuanghua <liguanghua@phicomm.com>
* CREATE DATE:   3/4/2014
*
* HISTORY    :
* 01   3/4/2014  LiGuanghua     Create.
**********************************************************************************
]]--

module("luci.phicomm.lib.bit", package.seeall)

bit={data32={}}
for i=1, 32 do
    bit.data32[i]=2^(32-i)  
end

--convert decimal int number to binary 
function bit:bit_d2b(arg)  
    local tr={}  
    for i=1,32 do  
        if arg >= self.data32[i] then  
			tr[i]=1  
			arg=arg-self.data32[i]  
        else  
			tr[i]=0  
        end
    end  
    return   tr  
end

--convert binary number to decimal
function bit:bit_b2d(arg)  
    local nr=0  
    for i=1,32 do  
        if arg[i] ==1 then  
			nr=nr+2^(32-i)  
        end  
    end  
    return  nr  
end

--bit operation xor
function bit:bit_xor(a,b)  
    local op1=self:bit_d2b(a)  
    local op2=self:bit_d2b(b)  
    local r={}  
  
    for i=1,32 do  
        if op1[i]==op2[i] then  
            r[i]=0  
        else  
            r[i]=1  
        end  
    end  
    return self:bit_b2d(r)  
end

--bit operation and
function bit:bit_and(a,b)  
    local op1=self:bit_d2b(a)  
    local op2=self:bit_d2b(b)  
    local r={}
      
    for i=1, 32 do  
        if op1[i]==1 and op2[i]==1  then  
            r[i]=1  
        else  
            r[i]=0  
        end  
    end  
    return  self:bit_b2d(r)  
end

--bit operation or
function bit:bit_or(a,b)  
    local op1=self:bit_d2b(a)  
    local op2=self:bit_d2b(b)  
    local r={}  
      
    for i=1,32 do  
        if  op1[i]==1 or op2[i]==1   then  
            r[i]=1  
        else  
            r[i]=0  
        end  
    end  
    return self:bit_b2d(r)  
end

--bit operation not
function bit:bit_not(a)  
    local op1=self:bit_d2b(a)  
    local r={}  
  
    for i=1,32 do  
        if op1[i]==1 then  
            r[i]=0  
        else  
            r[i]=1  
        end  
    end  
    return self:bit_b2d(r)  
end

--bit operation:right shift
function bit:bit_rshift(a, n)  
    local op1=self:bit_d2b(a)  
    local r=self:bit_d2b(0)  
      
    if n <= 32 and n >= 0 then  
        for i=1,n do  
            for i=31,1,-1 do  
                op1[i+1]=op1[i]  
            end  
            op1[1]=0  
        end  
		r=op1
    end
    return self:bit_b2d(r)  
end

--bit operation:left shift
function bit:bit_lshift(a,n)  
    local op1=self:bit_d2b(a)  
    local r=self:bit_d2b(0)  
      
    if n <= 32 and n >= 0 then  
        for i=1,n   do  
            for i=1,31 do  
                op1[i]=op1[i+1]  
            end  
            op1[32]=0  
        end  
		r=op1  
    end  
    return self:bit_b2d(r)  
end

--print bit array
function bit:bit_print(ta)  
    local sr=""  
    for i=1,32 do  
        sr=sr..ta[i]  
    end
    print(sr)  
end