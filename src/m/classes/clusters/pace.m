%PACE class definition
%
%   Usage:
%      cluster=pace();
%      cluster=pace('np',4);
%      cluster=pace('np',4,'login','username');

classdef pace 
	properties (SetAccess=public)
	% {{{
		name            = 'login-phoenix-4.pace.gatech.edu' %Phoenix cluster name
		login           = ''; %personal login
		numnodes        = 1; %number of nodes requested
		np              = 4; %number of processors per node
		mem             = 5; %memory requested [GB]
		port            = 0;
		queue           = 'inferno'; %queue
		time            = 60; %time requested per run [minutes]
		accountname     = 'GT-arobel3-atlas'; %group account name
		codepath        = ''; %path to issm binaries
		executionpath   = ''; %path for execution folder
	%}}}
	end
	methods
		function cluster=pace(varargin) % {{{
			cluster=AssignObjectFields(pairoptions(varargin{:}),cluster);
		end
		%}}}
		function disp(cluster) % {{{
			%  display the object
			disp(sprintf('class ''%s'' object ''%s'' = ',class(cluster),inputname(1)));
			disp(sprintf('    name of cluster (e.g. login-phoenix-4.pace.gatech.edu): %s',cluster.name));
			disp(sprintf('    login (personal login): %s',cluster.login));
			disp(sprintf('    numnodes (advice: leave this to 1): %i',cluster.numnodes));
			disp(sprintf('    np (number of processors per node for each job): %i',cluster.np));
			disp(sprintf('    mem (memory request per job): %i',cluster.mem));
			disp(sprintf('    port: %i',cluster.port));
			disp(sprintf('    queue (inferno/embers): %s',cluster.queue));
			disp(sprintf('    time (run time per job in minutes): %i',cluster.time));
			disp(sprintf('    codepath (directory with ISSM binaries): %s',cluster.codepath));
			disp(sprintf('    executionpath (directory for the outputs): %s',cluster.executionpath));
			disp(sprintf('    accountname (PI account): %s',cluster.accountname));
		end
		%}}}
		function md = checkconsistency(cluster,md,solution,analyses) % {{{

			available_queues        = {'inferno','embers'};
			queue_requirements_time = [30240,480];
         queue_requirements_np   = [28,28];
         QueueRequirements(available_queues,queue_requirements_time,queue_requirements_np,cluster.queue,cluster.np,cluster.time)
		
		end
		%}}}
		function BuildQueueScript(cluster,dirname,modelname,solution,io_gather,isvalgrind,isgprof,isdakota,isoceancoupling) % {{{

			executable = 'issm.exe';

			if(isvalgrind), disp('valgrind not supported by cluster, ignoring...'); end
			if(isgprof),    disp('gprof not supported by cluster, ignoring...'); end

			%write queuing script 
			fid=fopen([modelname '.queue'],'w');
			fprintf(fid,'#!/bin/sh\n');
			fprintf(fid,'#PBS -l walltime=%i\n',cluster.time*60); %conversion of walltime from minutes to seconds.
			fprintf(fid,'#PBS -N %s\n',modelname);
			fprintf(fid,'#PBS -l nodes=1:ppn=%i\n',cluster.np);
			fprintf(fid,'#PBS -l pmem=%igb\n',cluster.mem);
			fprintf(fid,'#PBS -q %s\n',cluster.queue);
			fprintf(fid,'#PBS -A %s\n',cluster.accountname);
		
			fprintf(fid,'#PBS -o %s/%s/%s.outlog \n',cluster.executionpath,dirname,modelname);
         fprintf(fid,'#PBS -e %s/%s/%s.errlog \n\n',cluster.executionpath,dirname,modelname);

			fprintf(fid,'export PBS_O_WORKDIR=%s\n',[cluster.executionpath '/' dirname]);
			fprintf(fid,'cd $PBS_O_WORKDIR\n');
			fprintf(fid,'mpiexec -np %i %s/%s %s %s %s \n',cluster.np,cluster.codepath,executable,solution,[cluster.executionpath '/' dirname],modelname);	

			fclose(fid);

		end
		%}}}
		function UploadQueueJob(cluster,modelname,dirname,filelist) % {{{

			%compress the files into one zip.
			compressstring=['tar -zcf ' dirname '.tar.gz '];
			for i=1:numel(filelist),
				compressstring = [compressstring ' ' filelist{i}];
			end
			system(compressstring);

			disp('uploading input file and queuing script');
			issmscpout(cluster.name,cluster.executionpath,cluster.login,cluster.port,{[dirname '.tar.gz']});

		end %}}}
		function LaunchQueueJob(cluster,modelname,dirname,filelist,restart,batch) % {{{

			disp('launching solution sequence on remote cluster');
			if ~isempty(restart)
				launchcommand=['cd ' cluster.executionpath ' && cd ' dirname ' && qsub ' modelname '.queue '];
			else
				launchcommand=['cd ' cluster.executionpath ' && rm -rf ./' dirname ' && mkdir ' dirname ...
					' && cd ' dirname ' && mv ../' dirname '.tar.gz ./ && tar -zxf ' dirname '.tar.gz  && qsub ' modelname '.queue '];
			end
			issmssh(cluster.name,cluster.login,cluster.port,launchcommand);
		end %}}}
		function Download(cluster,dirname,filelist) % {{{

			%copy files from cluster to current directory
			directory=[cluster.executionpath '/' dirname '/'];
			issmscpin(cluster.name,cluster.login,cluster.port,directory,filelist);

		end %}}}
	end
end
