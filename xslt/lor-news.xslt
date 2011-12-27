<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>


<xsl:template match="/">
	<plist version="1.0">
	<array>
		
		<xsl:apply-templates select="/html/body" />
		
	</array>
	</plist>
</xsl:template>

<xsl:template match="head"/>

<xsl:template match="/html/body/div/div/div">
	<xsl:if test="@class='news'">
		<dict>
			<xsl:apply-templates select="h2/a"/>
		</dict>
	</xsl:if>
</xsl:template>

<xsl:template match="h2/a">
	<key><xsl:text>title</xsl:text></key>
	<string><xsl:value-of select="text()"/></string>
</xsl:template>

<xsl:template match="/html/body/div">
	<xsl:apply-templates select="/html/body/div/div/div"/>
</xsl:template>

<xsl:template match="/html/body/script"/>
<xsl:template match="/html/body/p"/>
<!--
<xsl:template match="/html/body//*" priority="1" />

<xsl:template match="/" priority="1"> 
	<xsl:for-each select="//*[@*]">
		<xsl:if test="name()='div' and @class='news'">
			<p><xsl:value-of select="namespace-uri()"/></p><xsl:text>
</xsl:text>
				!-
				<b><xsl:value-of select="name()"/></b>
				<i><xsl:text> (</xsl:text>
				<xsl:value-of select="@class" />
				<xsl:text>):</xsl:text></i>
				<dl>
					<xsl:apply-templates select="@*"/>
				</dl>
				-
		</xsl:if>
	</xsl:for-each>
</xsl:template>
-->
<!--
<xsl:template match="@*" priority="1">
		<dt><xsl:value-of select="name()"/></dt>
		<dd>
			<xsl:value-of select="."/>
			<xsl:text> [ </xsl:text> 
			<xsl:value-of select="id(.)"/> 
			<xsl:text>]</xsl:text>
		</dd>
</xsl:template>
-->

</xsl:stylesheet>