<?xml version="1.0" encoding="UTF-8"?> 
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no" omit-xml-declaration="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="/">
   <ConnexRequiredFields>
     <Credentials>
       <requestId><xsl:value-of select="ConnexRequestWrapper/Message/@RequestId"/></requestId>
       <requestTag><xsl:value-of select="ConnexRequestWrapper/Message/@RequestTag"/></requestTag>
       <userName><xsl:value-of select="ConnexRequestWrapper/Message/@UserName"/></userName>
       <userKey><xsl:value-of select="ConnexRequestWrapper/Message/@UserKey"/></userKey>
       <methodName><xsl:value-of select="ConnexRequestWrapper/Message/@MethodName"/></methodName>
       <methodId><xsl:value-of select="ConnexRequestWrapper/Message/@MethodId"/></methodId>
     </Credentials>
     <Payload><xsl:copy-of select="ConnexRequestWrapper/Message/RiskPayload"/></Payload>
   </ConnexRequiredFields>
 </xsl:template>
</xsl:stylesheet>
