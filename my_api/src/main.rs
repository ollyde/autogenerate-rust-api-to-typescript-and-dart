use salvo::cors::Cors;
use salvo::hyper::Method;
use salvo::oapi::extract::*;
use salvo::prelude::*;

#[endpoint]
async fn hello(name: QueryParam<String, false>) -> String {
    format!("Hello, {}!", name.as_deref().unwrap_or("World"))
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt().init();

    let router = Router::new().push(Router::with_path("hello").get(hello));

    let doc = OpenApi::new("test api", "0.0.1").merge_router(&router);

    let cors = Cors::new()
        .allow_origin("*")
        .allow_methods(vec![Method::GET, Method::POST, Method::DELETE])
        .into_handler();

    let router = router
        .push(doc.into_router("/api-doc/openapi.json"))
        .push(SwaggerUi::new("/api-doc/openapi.json").into_router("ui"))
        .hoop(cors);

    let acceptor = TcpListener::new("127.0.0.1:5800").bind().await;
    Server::new(acceptor).serve(router).await;
}
