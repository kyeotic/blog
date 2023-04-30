---
title: "MultipartForm FileUpload with RestSharp"
pathname: "/restsharp-file-upload"
publish_date: 2014-12-26
tags: ["RestSharp", "file-upoad"]
---

[RestSharp](https://github.com/restsharp/RestSharp) is handy .NET library for doing REST requests, and it claims to support Multi-part form/file uploads. It doesn't provide any documentation on how to do this though, and I recently got tripped up trying to [figure it out](https://github.com/restsharp/RestSharp/issues/524).

It turns out to be pretty easy though.

    	//The 2nd parameter is a short-hand of (stream) => fileStream.CopyTo(stream)
        request.AddFile("fileData", fileStream.CopyTo, filename);
        request.AlwaysMultipartFormData = true;
    
        //Add one of these for each form boundary you need
        request.AddParameter("key", "value", ParameterType.GetOrPost);
        
        RestClient.Execute(request);
    

That's all it takes.
