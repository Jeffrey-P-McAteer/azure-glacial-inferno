
#[macro_use]
pub mod macros;


fn main() {
  let args: Vec<String> = std::env::args().collect();

  let rt = tokio::runtime::Builder::new_multi_thread()
    .enable_all()
    .worker_threads(2)
    .build()
    .expect("Could not build tokio runtime!");

  return rt.block_on(management_t(args));

}

async fn management_t(args: Vec<String>) {

  println!("TODO");

  // unix socket?

  // intervals!

}




