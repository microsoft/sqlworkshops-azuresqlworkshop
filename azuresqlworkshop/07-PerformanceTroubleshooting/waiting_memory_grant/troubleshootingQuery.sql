select   
	convert(varchar(30), getdate(), 121) as query_runtime
	,r.session_id
	,r.blocking_session_id
	,r.status
	,r.cpu_time
	,r.total_elapsed_time
	,r.reads
	,r.writes
	,r.logical_reads
	,r.row_count
	,w.wait_duration_ms as task_wait_time
	,w.wait_type as task_wait_type
	,r.wait_type
	,r.wait_time
	,r.command
	,object_name(txt.objectid,txt.dbid) 'object_name'
	,ltrim(rtrim(replace(replace (substring(substring(text, (r.statement_start_offset/2)+1,  ((case r.statement_end_offset when -1 then datalength(text) else r.statement_end_offset  end - r.statement_start_offset)/2) + 1), 1, 1000), char(10), ' '), char(13), ' '))) [stmt_text]
	,mg.dop --Degree of parallelism 
	,mg.request_time  --Date and time when this query requested the memory grant.
	,mg.grant_time --NULL means memory has not been granted
	,mg.requested_memory_kb/ 1024.0 requested_memory_mb --Total requested amount of memory in megabytes
	,mg.granted_memory_kb / 1024.0 as granted_memory_mb --Total amount of memory actually granted in megabytes. NULL if not granted
	,mg.required_memory_kb / 1024.0 as required_memory_mb--Minimum memory required to run this query in megabytes. 
	,max_used_memory_kb / 1024.0 as max_used_memory_mb
	,mg.query_cost --Estimated query cost.
	,mg.timeout_sec --Time-out in seconds before this query gives up the memory grant request.
	,mg.resource_semaphore_id --Nonunique ID of the resource semaphore on which this query is waiting.
	,mg.wait_time_ms --Wait time in milliseconds. NULL if the memory is already granted.
	,case mg.is_next_candidate --Is this process the next candidate for a memory grant
		when 1 then 'Yes'
		when 0 then 'No'
		else 'Memory has been granted'
	end as is_next_candidate
	,qp.query_plan
from     
	sys.dm_exec_requests r
    inner join sys.dm_exec_query_memory_grants mg
		on (r.session_id = mg.session_id 
		and r.request_id = mg.request_id)
	inner join sys.dm_os_waiting_tasks w
		on (r.session_id = w.session_id)
		and (w.wait_type not in ('CXSYNC_PORT', 'CXPACKET', 'CXCONSUMER'))
    cross apply sys.dm_exec_sql_text (mg.[sql_handle]) as txt
	cross apply sys.dm_exec_query_plan (r.plan_handle) qp
order by 
	mg.granted_memory_kb desc
