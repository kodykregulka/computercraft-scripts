services are defined as lua programs that do not interact with the terminal at all
they are intended on running in the background and to be started through a running service-executor instance
the intention is that other programs will be able to request info or dictate commands to a service via event queue

the service-executor will have an API that can be communicated with through the event queue

commands and event types
service-executor start service_name args...
service-executor stop service_name args...
service-executor restart service_name args...
service-executor shutdown
	--shutsdown service-executor gracefully



implementation
uses the coroutine API
launches services in their own shell.run coroutine that can 