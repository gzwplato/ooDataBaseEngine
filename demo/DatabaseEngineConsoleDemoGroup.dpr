﻿<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <PropertyGroup>
        <ProjectGuid>{EED82BF1-EFE6-40F0-82B6-A8077A9541BD}</ProjectGuid>
    </PropertyGroup>
    <ItemGroup>
        <Projects Include="DatabaseEngineConsoleDemo.dproj">
            <Dependencies>..\dll\DataBaseEngineLib.dproj</Dependencies>
        </Projects>
        <Projects Include="..\dll\DataBaseEngineLib.dproj">
            <Dependencies/>
        </Projects>
    </ItemGroup>
    <ProjectExtensions>
        <Borland.Personality>Default.Personality.12</Borland.Personality>
        <Borland.ProjectType/>
        <BorlandProject>
            <Default.Personality/>
        </BorlandProject>
    </ProjectExtensions>
    <Target Name="DatabaseEngineConsoleDemo" DependsOnTargets="DataBaseEngineLib">
        <MSBuild Projects="DatabaseEngineConsoleDemo.dproj"/>
    </Target>
    <Target Name="DatabaseEngineConsoleDemo:Clean" DependsOnTargets="DataBaseEngineLib:Clean">
        <MSBuild Projects="DatabaseEngineConsoleDemo.dproj" Targets="Clean"/>
    </Target>
    <Target Name="DatabaseEngineConsoleDemo:Make" DependsOnTargets="DataBaseEngineLib:Make">
        <MSBuild Projects="DatabaseEngineConsoleDemo.dproj" Targets="Make"/>
    </Target>
    <Target Name="DataBaseEngineLib">
        <MSBuild Projects="..\dll\DataBaseEngineLib.dproj"/>
    </Target>
    <Target Name="DataBaseEngineLib:Clean">
        <MSBuild Projects="..\dll\DataBaseEngineLib.dproj" Targets="Clean"/>
    </Target>
    <Target Name="DataBaseEngineLib:Make">
        <MSBuild Projects="..\dll\DataBaseEngineLib.dproj" Targets="Make"/>
    </Target>
    <Target Name="Build">
        <CallTarget Targets="DatabaseEngineConsoleDemo;DataBaseEngineLib"/>
    </Target>
    <Target Name="Clean">
        <CallTarget Targets="DatabaseEngineConsoleDemo:Clean;DataBaseEngineLib:Clean"/>
    </Target>
    <Target Name="Make">
        <CallTarget Targets="DatabaseEngineConsoleDemo:Make;DataBaseEngineLib:Make"/>
    </Target>
    <Import Project="$(BDS)\Bin\CodeGear.Group.Targets" Condition="Exists('$(BDS)\Bin\CodeGear.Group.Targets')"/>
</Project>
