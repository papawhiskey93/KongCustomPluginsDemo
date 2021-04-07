local kong = kong
local ngx = ngx
--local concat = table.concat
--local lower = string.lower
--local find = string.find
local MyHeader = {}
--local cjson = require "cjson.safe" 
local cjson = require "cjson"

local table_insert = table.insert
local get_uri_args = kong.request.get_query
local set_uri_args = kong.service.request.set_query
local clear_header = kong.service.request.clear_header
local get_header = kong.request.get_header
local set_header = kong.service.request.set_header
local get_headers = kong.request.get_headers
local set_headers = kong.service.request.set_headers
local set_method = kong.service.request.set_method
local set_path = kong.service.request.set_path
local get_raw_body = kong.request.get_raw_body
local set_raw_body = kong.service.request.set_raw_body
local encode_args = ngx.encode_args
local ngx_decode_args = ngx.decode_args
local type = type
local str_find = string.find
local pcall = pcall
local pairs = pairs
local error = error
local rawset = rawset
--local pl_copy_table = pl_tablex.deepcopy

--local jwt = require "luajwt"
local key = "odin"
local alg = "HS256"
local username = ""

local jwt_decoder = require "kong.plugins.myheader.jwt_parser"

local fmt = string.format
local kong = kong
local type = type
local error = error
local ipairs = ipairs
local tostring = tostring
local re_gmatch = ngx.re.gmatch

MyHeader.PRIORITY = 1000


-- String to array decoder
local function read_json_body(body)
  if body then
    return cjson.decode(body)
  end
end

local function parse_json(body)
  if body then
    local status, res = pcall(cjson.decode, body)
    if status then
      return res
    end
  end
end

 local function update_body_params(token)
	
	  local jwt ,err2= jwt_decoder:new(token)
	  local claims = jwt.claims
	  local jwt_username = claims["username"]
	if jwt_username then
	  print("start Body modification function ")
		local body = get_raw_body()
		local parameters = parse_json(body)
		
		if parameters == nil then
			parameters = {}			
		end
		print(parameters["email"])
		print(parameters["TenantId"])
		
		if not parameters["TenantId"] or not parameters["OMSId"] then
			return false, { status = 401, message = "Invalid body params : TenantId/OMSId" }
		end
		parameters["LastUpdateTime"] = os.time(os.date("!*t"))
		parameters["UpdatedBy"] = jwt_username
		local bodyNew = cjson.encode(parameters)
		set_raw_body(bodyNew)
		print("End Body modification function ")
		return true
	else
		return false, { status = 401, message = "No username found JWT token" }
	end
	
end

local function verify_jwt_signature(token)
--verify token type
local token_type = type(token)
  if token_type ~= "string" then
    if token_type == "nil" then
      return false, { status = 401, message = "Unauthorized" }
    elseif token_type == "table" then
      return false, { status = 401, message = "Multiple tokens provided" }
    else
      return false, { status = 401, message = "Unrecognizable token" }
    end
  end
  
  -- Decode token to find out who the consumer is
  local jwt, err = jwt_decoder:new(token)
  if err then
    return false, { status = 401, message = "Bad token; " .. tostring(err) }
  end  
  
  if not jwt:verify_signature(key) then
    return false, { status = 401, message = "Invalid signature" }
  end
  return true
  
end


local function verify_and_transform_json_body(conf)
	print("start verify_and_transform_json_body function ")
	local token = ""
	print(kong.request.get_method())
	local request_headers = kong.request.get_headers()
	local token_header = request_headers["authorization"] 
	if token_header then
      local iterator, iter_err = re_gmatch(token_header, "\\s*[Bb]earer\\s+(.+)")
      local m, err = iterator()
	  token = m[1] 
	else
		return kong.response.exit(401,{ message = "Bearer Token not found in header" })
	end
	local ok, err = verify_jwt_signature(token)
	print(ok)
	--print(err.message)
	if not ok then
		print("Inside Not ok")
		return kong.response.exit(err.status, { message = err.message })	
	elseif kong.request.get_method() == "POST" then	
		local body_ok,body_err = update_body_params(token)
		if not body_ok then
			return kong.response.exit(body_err.status, { message = body_err.message })	
		end
	end
	
	print("end verify_and_transform_json_body function ")
end
 

function MyHeader:header_filter(conf)
 
end


function MyHeader:body_filter(config)

end

function MyHeader:access(conf)
	print("start access function ")
	
  verify_and_transform_json_body(conf)
  print("end access function ")
end
return MyHeader

